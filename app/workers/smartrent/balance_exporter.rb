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
      
      ["_id", "email", "first_name", "last_name", "status", "balance_min", "balance_max", "move_in_min", "move_in_max", "property_id", "activated", "subscribed"].each do |k|
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
          
        elsif k == "move_in_min" && (Date.parse(val) rescue nil)
          arr << "first_move_in >= :#{k}"
          hash[k.to_sym] = Date.parse(val).to_s(:db)

        elsif k == "move_in_max" && (Date.parse(val) rescue nil)
          arr << "first_move_in <= :#{k}"
          hash[k.to_sym] = Date.parse(val).to_s(:db)
          
        elsif k == "first_name"
          arr << "#{k} LIKE :#{k}"
          hash[k.to_sym] = "%#{val}%"
          
        elsif k == "last_name"
          arr << "#{k} LIKE :#{k}"
          hash[k.to_sym] = "%#{val}%"
          
        elsif k == "activated" && @params[k] == "true"
          arr << "confirmed_at IS NOT NULL"
          
        elsif k == "subscribed" && @params[k] == "true"
          arr << "subscribed = 1"
          
        else
          arr << "#{k} = :#{k}"
          hash[k.to_sym] = "#{val}"
        end  
      end
      
      Smartrent::Resident.joins(:resident_properties).distinct("smartrent_residents.id").where(arr.join(" AND "), hash)
    end

    def self.init(params)
      @params = params

      return self
    end

    def self.generate_csv
      file_name = "SmartRentBalance_#{Time.now.strftime('%Y%m%d')}.csv"
      
      tenant_code_dict = {}
      unit_dict = {}
      
      # we can keep it here, it run fast.
      Unit.find_in_batches do |units|
        units.each do |u|
          unit_dict["#{u.property_id}_#{u.code}"] = u.id
        end
      end
      
      csv_string = CSV.generate() do |csv|
        csv << ["First Name", "Last Name", "Email", "Current Property", "Past Properties", "SmartRent Status", "SmartRent Balance", "Tenant Code", "Unit Code", "Move In", "Email Check", "Subscribe Status", "Activation Date"]
        batch_count = 0
        
        balances.includes(:resident_properties => :property).find_in_batches do |bs|
          batch_count += 1
          pp "batch_count: #{batch_count}"
          
          # we should build tenant_code_dict here, it will run fast for just 1000 residents
          ::Resident.where(:_id.in => bs.collect{|s| s.crm_resident_id.to_s }).each_with_index do |r, i|
            pp "  tenant_code_dict #{i}" if i%100==0
            r.units.each do |u|
              tenant_code_dict["#{r._id}_#{u.unit_id}"] = u.tenant_code
            end
          end
          
          bs.each do |b|
            curr_rp = nil
            curr = nil
            past = []
            
            b.resident_properties.each do |rp|
              next if !rp.property
              
              if rp.status == Smartrent::ResidentProperty::STATUS_CURRENT
                if !curr
                  curr_rp = rp
                  curr = rp.property
                end
                
              elsif rp.status == Smartrent::ResidentProperty::STATUS_NOTICE || rp.status == Smartrent::ResidentProperty::STATUS_FUTURE # make sure the export file will not show blank current property
                if !curr
                  curr_rp = rp
                  curr = rp.property
                end
                
              elsif rp.status == Smartrent::ResidentProperty::STATUS_PAST
                past << rp.property
              end
            end
            
            unit_code = curr_rp ? curr_rp.unit_code : nil
            unit_id =  unit_dict["#{curr_rp.property_id}_#{curr_rp.unit_code}"] if curr_rp
            tenant_code = tenant_code_dict["#{b.crm_resident_id}_#{unit_id}"] if unit_id
            
            csv << [
              b.first_name,
              b.last_name,
              b.email,
              curr ? curr.name : "",
              past.collect{|p| p.name.to_s }.join(", "),
              b.smartrent_status,
              b.balance,
              tenant_code,
              unit_code,
              b.first_move_in ? b.first_move_in.strftime("%Y-%m-%d") : "",
              b.email_check,
              b.subscribe_status,
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

        ::Notifier.system_message("SmartRent Balance Data",
          "Your file was exported successfully.
          <br><br> 
          <a href='http://#{HOST}/downloads/#{file_name}'>Download File</a> 
          <br><br> To protect your data the download link will work for the next two hours, or until you download the file
          <br>
          <br>
          CRM Team
          <br>
          #{HELP_EMAIL}", @params["recipient"], {"from" => OPS_EMAIL})#.deliver_now

        Resque.enqueue_at(Time.now + 2.hours, DownloadCleaner, file_name)

      rescue Exception => e
        error_details = "#{e.class}: #{e}"
        error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
        p "ERROR: #{error_details}"

        ::Notifier.system_message("[BalanceExporter] FAILURE", "ERROR DETAILS: #{error_details}",
          ADMIN_EMAIL, {"from" => OPS_EMAIL})#.deliver_now

        ::Notifier.system_message("SmartRent Balance Data",
          "There was an error while exporting your data, please contact #{HELP_EMAIL} for help",
          @params["recipient"], {"from" => OPS_EMAIL})#.deliver_now
      end
    end
    
  end
end