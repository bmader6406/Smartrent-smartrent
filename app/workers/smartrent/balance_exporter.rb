require 'csv'
require 'net/ftp'

module Smartrent
  class BalanceExporter

    def self.queue
      :crm_immediate
    end
    
    def self.sendible?
      balances.count < 1000
    end

    def self.balances
      query = 
      
      arr = []
      hash = {}
      
      ["_id", "email", "first_name", "last_name", "status", "balance_min", "balance_max", "property_id", "activated"].each do |k|
        next if @params[k].blank?
        val = @params[k].strip
        if k == "_id"
          arr << "id = :id"
          hash[:id] = "#{val}"
          
        elsif k == "status"
          arr << "smartrent_status = :#{k}"
          hash[k.to_sym] = "#{val}"
          
        elsif k == "property_id"
          arr << "smartrent_resident_properties.property_id = :#{k}"
          hash[k.to_sym] = "#{val}"
          
        elsif k == "balance_min"
          arr << "balance >= :#{k}"
          hash[k.to_sym] = "#{val.to_i}"

        elsif k == "balance_max"
          arr << "balance <= :#{k}"
          hash[k.to_sym] = "#{val.to_i}"
          
        elsif k == "first_name"
          arr << "#{k} LIKE :#{k}"
          hash[k.to_sym] = "%#{val}%"
          
        elsif k == "last_name"
          arr << "#{k} LIKE :#{k}"
          hash[k.to_sym] = "%#{val}%"
          
        elsif k == "activated" && @params[k] == "true"
          arr << "confirmed_at IS NOT NULL"
          
        else
          arr << "#{k} = :#{k}"
          hash[k.to_sym] = "#{val}"
        end  
      end
      
      Smartrent::Resident.joins(:resident_properties).where(arr.join(" AND "), hash)
    end

    def self.init(params)
      @params = params

      return self
    end

    def self.generate_csv
      file_name = "SmartRentBalance_#{Time.now.strftime('%Y%m%d')}.csv"

      csv_string = CSV.generate() do |csv|
        csv << ["First Name", "Last Name", "Email", "Current Property", "Past Properties", "Status", "Balance", "Activation Date"]
        
        balances.includes(:resident_properties => :property).find_in_batches do |bs|
          bs.each do |b|
            curr = nil
            past = []
            
            b.resident_properties.each do |rp|
              next if !rp.property
              if rp.status == Smartrent::ResidentProperty.STATUS_CURRENT
                curr = rp.property
              elsif rp.status == Smartrent::ResidentProperty.STATUS_PAST
                past << rp.property
              end
            end
            
            csv << [
              b.first_name,
              b.last_name,
              b.email,
              curr ? curr.name : "",
              past.collect{|p| p.name.to_s }.join(", "),
              b.smartrent_status,
              b.balance,
              b.confirmed_at ? b.confirmed_at.strftime("%Y-%m-%d") : ""
            ]
          end
        end
      end

      return csv_string, file_name
    end

    def self.perform(params)
      begin
        csv_string, file_name = init(params).generate_csv

        file_name = "#{Time.now.to_i}_#{file_name}"

        File.open("#{TMP_DIR}#{file_name}", "wb") { |f| f.write(csv_string) }

        ::Notifier.system_message("Smartrent Balance Data",
          "Your file was exported successfully.
          <br><br> 
          <a href='http://#{HOST}/downloads/#{file_name}'>Download File</a> 
          <br><br> To protect your data the download link will work for the next two hours, or until you download the file
          <br>
          <br>
          CRM Team
          <br>
          help@hy.ly", @params["recipient"], {"from" => ::Notifier::EXIM_ADDRESS}).deliver_now

        Resque.enqueue_at(Time.now + 2.hours, DownloadCleaner, file_name)

      rescue Exception => e
        error_details = "#{e.class}: #{e}"
        error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
        p "ERROR: #{error_details}"

        ::Notifier.system_message("[BalanceExporter] FAILURE", "ERROR DETAILS: #{error_details}",
          ::Notifier::DEV_ADDRESS, {"from" => ::Notifier::EXIM_ADDRESS}).deliver_now

        ::Notifier.system_message("Smartrent Balance Data",
          "There was an error while exporting your data, please contact help@hy.ly for help",
          @params["recipient"], {"from" => ::Notifier::EXIM_ADDRESS}).deliver_now
      end
    end
    
  end
end