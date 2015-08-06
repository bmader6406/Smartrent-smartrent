# https://docs.google.com/spreadsheets/d/1D3lSgqPxrUVIozZwXmgKyl3pqSW6_NYDUOtNoK5MGAU/edit#gid=1524520992

module Smartrent
  class MonthlyStatusUpdater

    def self.queue
      :crm_immediate
    end
  
    def self.perform(period_start = nil)
      period_start = (period_start || Time.now.prev_month).utc.beginning_of_month
      
      pp "period_start: #{period_start}"
      
      Smartrent::Resident.all.each do |r|
        # it is good to catch any resident which cause the below code fail rather then stop the calculation
        begin
          # get properties that the resident live in
          live_in_properties = r.resident_properties.select{|p| p.move_in_date <= period_start &&  (p.move_out_date.blank? || p.move_out_date > Time.now) }
          
          # get smartrent eligible property
          smartrent_properties = live_in_properties.select{|rp| rp.property.status.to_s.include?(Property.STATUS_CURRENT) && rp.property.is_smartrent }
          
          # active => inactive or active => + rewards
          if r.smartrent_status == Smartrent::Resident.SMARTRENT_STATUS_ACTIVE
            
            if !live_in_properties.empty?
              
              if !smartrent_properties.empty?
                create_monthly_rewards(r, smartrent_properties, period_start)
                
              else #Resident doesn't live in any smartrent property, set it's expiry to 1 year from the period start
                r.update_attributes({
                  :smartrent_status => Smartrent::Resident.SMARTRENT_STATUS_INACTIVE,
                  :expiry_date => period_start + 1.year
                })
              end
            
            else # resident moved out, not live in any properties
              r.update_attributes({
                :smartrent_status => Smartrent::Resident.SMARTRENT_STATUS_INACTIVE,
                :expiry_date => period_start + 60.days
              })

            end
          end
      
          # inactive => expired or inactive => active
          if r.smartrent_status == Smartrent::Resident.SMARTRENT_STATUS_INACTIVE
            
            if smartrent_properties.empty?            
              if period_start >= r.expiry_date
                r.update_attributes(:smartrent_status => Smartrent::Resident.SMARTRENT_STATUS_EXPIRED)
              end
              
            else
              r.update_attributes({
                :smartrent_status => Smartrent::Resident.SMARTRENT_STATUS_ACTIVE,
                :expiry_date => nil
              })
              
              create_monthly_rewards(r, smartrent_properties, period_start)
            end
          end
          
        rescue  Exception => e
          error_details = "#{e.class}: #{e}"
          error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
          p "ERROR: #{error_details}"

          ::Notifier.system_message("[Smartrent::MonthlyStatusUpdater] FAILURE", "ERROR DETAILS: #{error_details}",
            ::Notifier::DEV_ADDRESS, {"from" => ::Notifier::EXIM_ADDRESS}).deliver_now
        end
      end # /all.each
      
    end # /perform
    
    def self.create_monthly_rewards(resident, smartrent_properties, period_start)
      smartrent_properties.each do |rp|
        # create monthly reward if not created for this month
        if resident.rewards.where(:property_id => rp.property_id, :type_ => Reward.TYPE_MONTHLY_AWARDS, :period_start => [period_start, period_start.end_of_month]).count == 0
          resident.rewards.create({
            :property_id => rp.property_id,
            :type_ => Reward.TYPE_MONTHLY_AWARDS,
            :period_start => period_start,
            :period_end => period_start.end_of_month,
            :amount => Setting.monthly_award,
            :months_earned => 1
          })
        end
      end
    end
    
  end
end
