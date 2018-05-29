require 'csv'
require 'net/ftp'

# - Export resident list with total rewards point, upload to hy.ly FTP site
# - app.hy.ly will check the ftp folder and import the resident list


module Smartrent
  class ResidentExporter

    def self.queue
      :crm_immediate
    end
    
    def self.perform(time = Time.now, type = "welcome")
      time = Time.parse(time) if time.kind_of?(String)
      time = time.in_time_zone('Eastern Time (US & Canada)')
      
      @type = type
      
      if type == "welcome"
        export_welcome_email_residents(time)
        
      elsif type == "statement"
        export_statement_email_residents(time)
        
      elsif type == "quarterly_move_in"
        export_quarterly_move_in_residents(time)
      
      elsif type == "monthly_move_in"
        export_monthly_move_in_residents(time)
        
      elsif type == "initial"
        export_initial(time)
        
      end
      
      Notifier.system_message("[SmartRent] ResidentExporter - SUCCESS", "Type: #{type}, executed at #{Time.now}", ADMIN_EMAIL).deliver_now
    end
    
    # welcome email is sent monthly
    def self.export_welcome_email_residents(time)
      batch_name = "SmartRent-Welcome-#{time.strftime("%m/%Y")}"
      
      file_name = "WelcomeEmail_#{Time.now.strftime("%m%d%Y")}.csv"
      
      @index = 0
      
      CSV.open("#{TMP_DIR}#{file_name}", "w") do |csv|
        csv << ["Full Name", "Email", "SmartRent Balance", "SmartRent Status", "Batch"]
        
        conditions = "smartrent_status IN (?) AND created_at #{(time.beginning_of_month..time.end_of_month).to_s(:db)}"
        
        Smartrent::Resident.includes(:rewards)
          .where(conditions, [
            Smartrent::Resident::STATUS_ACTIVE
          ]).find_in_batches do |residents|
            add_csv_row(csv, residents, batch_name)
        end
      end
      
      # upload ftp
      upload(file_name)
    end
    
    # statement email is sent quaterly
    def self.export_statement_email_residents(time)
      batch_name = "SmartRent-Statement-#{get_quarter(time)}/#{time.end_of_quarter.strftime("%Y")}"
      
      file_name = "StatementEmail_#{Time.now.strftime("%m%d%Y")}.csv"
      
      @index = 0
      
      #export all active/inactive smartrent residents
      CSV.open("#{TMP_DIR}#{file_name}", "w") do |csv|
        csv << ["Full Name", "Email", "SmartRent Balance", "SmartRent Status", "Batch"]
        
        Smartrent::Resident.includes(:rewards)
          .where("smartrent_status IN (?) AND created_at < '#{time.end_of_quarter.to_s(:db)}'", [
            Smartrent::Resident::STATUS_ACTIVE, 
            Smartrent::Resident::STATUS_INACTIVE
          ]).find_in_batches do |residents|
            add_csv_row(csv, residents, batch_name)
        end
      end
      
      # upload ftp
      # upload(file_name)
    end
    
    def self.export_monthly_move_in_residents(time)
      batch_name = "SmartRent-Monthly-#{time.strftime("%m/%Y")}"
      
      file_name = "MonthlyMoveIn_#{time.strftime("%m%Y")}.csv"
      
      @index = 0
      
      CSV.open("#{TMP_DIR}#{file_name}", "w") do |csv|
        csv << ["Full Name", "Email", "SmartRent Balance", "SmartRent Status", "Batch"]
        
        Smartrent::Resident.includes(:rewards)
          .where("smartrent_status IN (?) AND first_move_in #{(time.beginning_of_month..time.end_of_month).to_s(:db)}", [
            Smartrent::Resident::STATUS_ACTIVE, 
            Smartrent::Resident::STATUS_INACTIVE
          ]).find_in_batches do |residents|
            add_csv_row(csv, residents, batch_name)
        end
      end
      
      # upload ftp
      upload(file_name)
    end
    
    # not needed
    def self.export_quarterly_move_in_residents(time)
      batch_name = "SmartRent-Quarterly-#{get_quarter(time)}_#{time.end_of_quarter.strftime("%Y")}"
      
      file_name = "QuarterlyMoveIN_#{Time.now.strftime("%m%d%Y")}.csv"
      
      @index = 0
      
      CSV.open("#{TMP_DIR}#{file_name}", "w") do |csv|
        csv << ["Full Name", "Email", "SmartRent Balance", "SmartRent Status", "Batch"]
        
        Smartrent::Resident.includes(:rewards)
          .where("smartrent_status IN (?) AND first_move_in #{(time.beginning_of_quarter..time.end_of_quarter).to_s(:db)}", [
            Smartrent::Resident::STATUS_ACTIVE, 
            Smartrent::Resident::STATUS_INACTIVE
          ]).find_in_batches do |residents|
            add_csv_row(csv, residents, batch_name)
        end
      end
      
      # upload ftp
      upload(file_name)
    end
    
    # manual
    def self.export_initial(time)
      batch_name = "Smartrent-Initial-#{Time.now.strftime("%m/%d/%Y")}"
      
      file_name = "#{Rails.env}_Initial_#{Time.now.strftime("%m%d%Y")}.csv"
      
      @index = 0
      
      #export active/inactive smartrent residents who have been in the system for more than 2 months
      CSV.open("#{TMP_DIR}#{file_name}", "w") do |csv|
        csv << ["Full Name", "Email", "SmartRent Balance", "SmartRent Status", "Batch"]
        
        Smartrent::Resident.includes(:rewards)
          .where("smartrent_status IN (?) AND first_move_in <= '2016-07-01 04:59:59'", [
            Smartrent::Resident::STATUS_ACTIVE, 
            Smartrent::Resident::STATUS_INACTIVE
          ]).find_in_batches do |residents|
            add_csv_row(csv, residents, nil)
        end
      end
      
      # upload ftp
      upload(file_name)
    end
    
    def self.add_csv_row(csv, residents, batch_prefix)
      #"Full Name", "Email", "SmartRent Balance", "SmartRent Status", "Batch"
      crm_residents = {}
      ::Resident.where(:email_lc.in => residents.collect{|r| r.email.to_s.downcase }).each do |cr|
        crm_residents[cr.email_lc] = cr
      end
      
      july01 = Time.parse("2016-07-01 00:00:00 -0500")

      residents.each do |r|
        @index += 1
        pp "index: #{@index}"
        
        r.crm_resident = crm_residents[r.email.to_s.downcase]
        
        if r.crm_resident

          if ["statement", "quarterly_move_in", "monthly_move_in"].include?(@type)
            batch_name = "#{batch_prefix}: #{r.smartrent_status}"
            
          elsif @type == "welcome"
            # keep batch_name as is
            batch_name = batch_prefix
            
          elsif r.first_move_in
            if r.first_move_in < july01
              batch_name = "move in dates < 7/1/2016 - #{r.smartrent_status}"
              
            elsif r.first_move_in >= july01 && r.first_move_in < july01.end_of_month
              batch_name = "move in dates in 07/2016 - #{r.smartrent_status}"
              
            else
              next  
            end
          end
          
          csv << [
            r.name,
            r.email,
            "$#{ActionController::Base.helpers.number_with_delimiter(r.total_rewards.to_i)}",
            r.smartrent_status,
            batch_name
          ]
        else
          pp "CRM Resident not found for SR Resident ID: #{r.id}, #{r.email}"
        end
      end
    end
    
    def self.get_quarter(date)
      quarters = ["Q1", "Q2", "Q3", "Q4"]
      quarters[(date.month - 1) / 3]
    end
    
    def self.upload(file_name)
      ftp = Net::FTP.new()
      ftp.passive = true
      ftp.connect("ftp.hy.ly")
      ftp.login("bozzuto", "TBEj1E5I")
      ftp.putbinaryfile("#{TMP_DIR}#{file_name}", "/smartrent/#{Rails.env}/#{file_name}")
      ftp.close
    end
    
  end
end