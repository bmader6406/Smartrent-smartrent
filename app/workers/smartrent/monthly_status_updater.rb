# https://docs.google.com/spreadsheets/d/1D3lSgqPxrUVIozZwXmgKyl3pqSW6_NYDUOtNoK5MGAU/edit#gid=1524520992

module Smartrent
  class MonthlyStatusUpdater

    def self.queue
      :crm_immediate
    end
  
    def self.perform(period_start = nil)
      period_start = (period_start || Time.now.prev_month).beginning_of_month
      pp "period_start: #{period_start}"
      Smartrent::Resident.all.each do |r|
        # active => inactive or active => + rewards
        if r.smartrent_status == Smartrent::Resident.SMARTRENT_STATUS_ACTIVE
          # get properties that the resident live in
          live_in_properties = r.resident_properties.select{|p| p.move_out_date.blank? || p.move_out_date > Time.now }
          
          if !live_in_properties.empty?
            
            # get smartrent eligible property
            smartrent_properties = live_in_properties.select{|rp| rp.property.status.to_s.include?(Property.STATUS_CURRENT) && rp.property.is_smartrent }
            if smartrent_properties.present?
               smartrent_properties.each do |rp|
                
                # create monthly reward if not created for this month
                if r.rewards.where(:property_id => rp.property_id, :type_ => Reward.TYPE_MONTHLY_AWARDS, :period_start => [period_start, period_start.end_of_month]).count == 0
                  r.rewards.create({
                    :property_id => rp.property_id,
                    :type_ => Reward.TYPE_MONTHLY_AWARDS,
                    :period_start => period_start,
                    :period_end => period_start.end_of_month,
                    :amount => Setting.monthly_award
                  })
                end
              end
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
      
        # inactive => expired
        if r.smartrent_status == Smartrent::Resident.SMARTRENT_STATUS_INACTIVE
          
          if period_start >= r.expiry_date
            r.update_attributes(:smartrent_status => Smartrent::Resident.SMARTRENT_STATUS_EXPIRED)
          end
          
        end
      end
      
    end # /perform
    
  end
end
