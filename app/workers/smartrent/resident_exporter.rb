require 'csv'
require 'net/ftp'

# - Export resident list with total rewards point, upload to hy.ly FTP site
# - app.hy.ly will check the ftp folder and import the resident list


module Smartrent
  class ResidentExporter

    def self.queue
      :crm_immediate
    end
    
    def self.perform(time = Time.now)
      time = Time.parse(time) if time.kind_of?(String)
      time = time.in_time_zone('Eastern Time (US & Canada)')
      
      export_welcome_email_residents(time)
      export_statement_email_residents(time)
      
      Notifier.system_message("[SmartRent] ResidentExporter - SUCCESS", "Executed at #{Time.now}", Notifier::DEV_ADDRESS).deliver_now
    end
    
    # welcome email is sent monthly
    def self.export_welcome_email_residents(time)
      batch_name = "#{time.strftime("%Y %m")} New Account - SmartRent"
      
      if Rails.env.production?
        file_name = "WelcomeEmail_#{batch_name}.csv"
      else
        file_name = "stage_WelcomeEmail_#{batch_name}.csv"
      end
      
      @index = 0
      
      #export active/inactive smartrent residents who have been in the system for more than 2 months
      CSV.open("#{TMP_DIR}#{file_name}", "w") do |csv|
        csv << ["Full Name", "Email", "Smartrent Balance", "Smartrent Status", "Batch"]
        
        Smartrent::Resident.includes(:rewards)
          .where("smartrent_status IN (?) AND created_at #{(time.beginning_of_month..time.end_of_month).to_s(:db)}", [
            Smartrent::Resident.SMARTRENT_STATUS_ACTIVE, 
            Smartrent::Resident.SMARTRENT_STATUS_INACTIVE
          ]).find_in_batches do |residents|
            add_csv_row(csv, residents, batch_name)
        end
      end
      
      # upload ftp
      ftp = Net::FTP.new()
      ftp.passive = true
      ftp.connect("ftp.hy.ly")
      ftp.login("bozzuto", "bozzuto0804")
      ftp.putbinaryfile("#{TMP_DIR}#{file_name}", "/smartrent/welcome/#{file_name}")
      ftp.close
    end
    
    # statement email is sent quaterly
    def self.export_statement_email_residents(time)
      batch_name = "#{time.end_of_quarter.strftime("%Y %m")} SmartRent"
      
      if Rails.env.production?
        file_name = "StatementEmail_#{batch_name}.csv"
      else
        file_name = "stage_StatementEmail_#{batch_name}.csv"
      end
      
      @index = 0
      
      #export active/inactive smartrent residents who have been in the system for more than 2 months
      CSV.open("#{TMP_DIR}#{file_name}", "w") do |csv|
        csv << ["Full Name", "Email", "Smartrent Balance", "Smartrent Status", "Batch"]
        
        Smartrent::Resident.includes(:rewards)
          .where("smartrent_status IN (?) AND created_at > '#{time.beginning_of_quarter.to_s(:db)}'", [
            Smartrent::Resident.SMARTRENT_STATUS_ACTIVE, 
            Smartrent::Resident.SMARTRENT_STATUS_INACTIVE
          ]).find_in_batches do |residents|
            add_csv_row(csv, residents, batch_name)
        end
      end
      
      # upload ftp
      ftp = Net::FTP.new()
      ftp.passive = true
      ftp.connect("ftp.hy.ly")
      ftp.login("bozzuto", "bozzuto0804")
      ftp.putbinaryfile("#{TMP_DIR}#{file_name}", "/smartrent/statement/#{file_name}")
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
          csv << [r.name, r.email, r.total_rewards.to_i, r.smartrent_status, "#{batch_name}: #{r.smartrent_status}"]
        else
          pp "CRM Resident not found for SR Resident ID: #{r.id}, #{r.email}"
        end
      end
    end
    
  end
end