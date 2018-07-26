module Smartrent
  class MonthlyAwardUpdater

    def self.queue
      :crm_immediate
    end
  
    def self.perform(resident_email = nil, time=Time.now, scheduled_run = true)
      time = Time.parse(time) if time.kind_of?(String)
      time = time.in_time_zone('Eastern Time (US & Canada)')
      
      period_start = time.beginning_of_month
      
      total = 0
      if resident_email
        query = Smartrent::Resident.includes(:resident_properties => :property).where(email: resident_email) 
      else
        query = Smartrent::Resident.includes(:resident_properties => :property).where(smartrent_status: Smartrent::Resident::STATUS_ACTIVE)
      end

      query.each do |r|
        begin

          pp "email: #{r.email} monthly_award: #{period_start}"
          total += 1

          smartrent_property = r.resident_properties.select{|rp| (rp.status == 'Current' || rp.status== 'Notice') and rp.property.is_smartrent? }.last

          create_monthly_rewards(r, smartrent_property, period_start) if scheduled_run and smartrent_property

        rescue  Exception => e
          error_details = "#{e.class}: #{e}"
          error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
          p "ERROR: #{error_details}"
          p "[SmartRent] MonthlyStatusUpdater - FAILURE" if resident_email
          if !resident_email
            ::Notifier.system_message("[Smartrent::MonthlyAwardUpdater] FAILURE", "ERROR DETAILS: #{error_details}",
              ADMIN_EMAIL, {"from" => OPS_EMAIL}).deliver_now
          end
        end
      end

      Notifier.system_message("[SmartRent] MonthlyAwardUpdater - SUCCESS", "Executed at #{Time.now}", ADMIN_EMAIL).deliver_now if scheduled_run && !resident_email
      
    end 
    
    def self.create_monthly_rewards(resident, smartrent_property, period_start)
      # create monthly reward if not created for this month
      if resident.rewards.where(:type_ => Reward::TYPE_MONTHLY_AWARDS, :period_start => period_start, :period_end => period_start.end_of_month).count == 0
        if resident.total_rewards == 10000
          amount = 0
        else
          amount = Setting.monthly_award
        end
        pp "period_start: #{period_start},  >>  property_id: #{smartrent_property.property_id}, >> amount: >> #{amount}"
        resident.rewards.create({
          :property_id => smartrent_property.property_id,
          :type_ => Reward::TYPE_MONTHLY_AWARDS,
          :period_start => period_start,
          :period_end => period_start.end_of_month,
          :amount => amount,
          :months_earned => 1
          })
      end
    end

  end
end