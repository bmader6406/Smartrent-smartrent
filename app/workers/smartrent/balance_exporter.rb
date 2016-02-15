require 'csv'
require 'net/ftp'

# - Export resident list with total rewards point, upload to hy.ly FTP site
# - app.hy.ly will check the ftp folder and import the resident list


module Smartrent
  class BalanceExporter

    def self.queue
      :crm_immediate
    end
    
    def self.perform(move_in = nil)
      if move_in
        batch_name = "month_#{move_in.strftime("%m_%Y")}"
      else
        batch_name = "all_#{Time.now.strftime("%m_%d_%Y")}"
      end
      
      file_name = "residents_#{batch_name}.csv"
      
      @index = 0
      
      CSV.open("#{TMP_DIR}#{file_name}", "w") do |csv|
        csv << ["Full Name", "Email", "Smartrent Balance", "Smartrent Status", "Batch"]
        
        if move_in #export recent active resident  
          Smartrent::Resident.joins(:resident_properties).includes(:rewards)
            .where("smartrent_status = ? AND smartrent_resident_properties.move_in_date = ?", Smartrent::Resident.SMARTRENT_STATUS_ACTIVE, move_in.to_date).find_in_batches do |residents|
              add_csv_row(csv, residents, batch_name)
          end
          
        else # export all active resident
          Smartrent::Resident.includes(:rewards).where("smartrent_status = ?", Smartrent::Resident.SMARTRENT_STATUS_ACTIVE).find_in_batches do |residents|
            add_csv_row(csv, residents, "All")
          end
          
        end
      end
      
      # upload ftp
      ftp = Net::FTP.new()
      ftp.passive = true
      ftp.connect("ftp.hy.ly")
      ftp.login("bozzuto", "bozzuto0804")
      ftp.putbinaryfile("#{TMP_DIR}#{file_name}", "/smartrent/#{file_name}")
      ftp.close
    end
    
    def self.add_csv_row(csv, residents, batch_name)
      #"Full Name", "Email", "Smartrent Balance", "Smartrent Status", "Batch"
      crm_residents = {}
      ::Resident.where(:email_lc.in => residents.collect{|r| r.email.to_s.downcase }).each do |cr|
        crm_residents[cr.email_lc] = cr
      end

      residents.each do |r|
        @index += 1
        pp "index: #{@index}"
        
        r.crm_resident = crm_residents[r.email.to_s.downcase]
        csv << [r.name, r.email, r.total_rewards.to_i, r.smartrent_status, batch_name]
      end
    end
    
  end
end