require 'csv'
require 'net/ftp'

# - Export resident list with total rewards point, upload to hy.ly FTP site
# - app.hy.ly will check the ftp folder and import the resident list


module Smartrent
  class ResidentExporter

    def self.queue
      :crm_immediate
    end
    
    def self.perform(time = nil)
      if time
        time = Time.parse(time) if time.kind_of?(String)
        time = time.in_time_zone('Eastern Time (US & Canada)')

        batch_name = "new_active_#{time.strftime("%m_%Y")}"
      else
        batch_name = "all_active_#{Time.now.strftime("%m_%Y")}"
      end
      
      if Rails.env.production?
        file_name = "residents_#{batch_name}.csv"
      else
        file_name = "stage_residents_#{batch_name}.csv"
      end
      
      @index = 0
      
      CSV.open("#{TMP_DIR}#{file_name}", "w") do |csv|
        csv << ["Full Name", "Email", "Smartrent Balance", "Smartrent Status", "Batch"]
        
        if time #export active residents for a specified month
          Smartrent::Resident.includes(:rewards)
            .where("smartrent_status = ? AND created_at #{(time.beginning_of_month..time.end_of_month).to_s(:db)}", [
              Smartrent::Resident.SMARTRENT_STATUS_ACTIVE, 
              Smartrent::Resident.SMARTRENT_STATUS_INACTIVE
            ]).find_in_batches do |residents|
              add_csv_row(csv, residents, batch_name)
          end
          
        else # export all active resident
          Smartrent::Resident.includes(:rewards).where("smartrent_status = ?", [
            Smartrent::Resident.SMARTRENT_STATUS_ACTIVE, 
            Smartrent::Resident.SMARTRENT_STATUS_INACTIVE
          ]).find_in_batches do |residents|
            add_csv_row(csv, residents, batch_name)
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
        
        if r.crm_resident
          csv << [r.name, r.email, r.total_rewards.to_i, r.smartrent_status, batch_name]
        else
          pp "CRM Resident not found for SR Resident ID: #{r.id}, #{r.email}"
        end
      end
    end
    
  end
end