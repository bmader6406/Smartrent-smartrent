# https://docs.google.com/spreadsheets/d/1D3lSgqPxrUVIozZwXmgKyl3pqSW6_NYDUOtNoK5MGAU/edit#gid=1524520992

module Smartrent
  class MonthlyStatusUpdater

    def self.queue
      :crm_immediate
    end
  
    def self.perform(time, scheduled_run = true, created_at = nil, resident_id = nil)
      time = Time.parse(time) if time.kind_of?(String)
      time = time.in_time_zone('Eastern Time (US & Canada)')
      
      period_start = time.beginning_of_month
      
      # pp "period_start: #{period_start}"
      total = 0
      
      query = Smartrent::Resident
      query = query.where("created_at > ?", Time.parse(created_at).utc.to_s(:db)) if created_at
      query = query.where(:id => resident_id) if resident_id
      
      query.includes(:resident_properties => :property).find_in_batches do |residents|
        residents.each do |r|
          # it is good to catch any resident which cause the below code fail rather than stop the calculation
          begin
            # important: ignore resident who not move in any properties before the execution date, otherwise their status will changed from Active to Inactive
            next if r.resident_properties.all? {|rp| rp.move_in_date > period_start+15.days }
            total += 1
            # pp "total: #{total} - id #{r.id}, email: #{r.email}, #{r.smartrent_status}"

            # remove duplicate properties of resident
            # remove_duplicate_resident_properties(r)

            # get properties that the resident live in
            live_in_properties = r.resident_properties.select{|rp| rp.move_in_date <= period_start+15.days &&  (rp.move_out_date.blank? || rp.move_out_date > time) }
            # pp "live_in_properties:", live_in_properties
            
            if !live_in_properties.empty? && (r.smartrent_status == Smartrent::Resident::STATUS_EXPIRED || r.smartrent_status == Smartrent::Resident::STATUS_INACTIVE)
              r.smartrent_status = Smartrent::Resident::STATUS_ACTIVE
              r.save
            end

            # get smartrent eligible property
            smartrent_properties = live_in_properties.select{|rp| rp.property.eligible?(time) }
            # pp "smartrent_properties:", smartrent_properties

            move_out_smartrent_properties = r.resident_properties.select{|rp| rp.move_out_date && rp.move_out_date.month == time.month && rp.property.eligible?(time) }
            # pp "move_out_smartrent_properties", move_out_smartrent_properties
            
            # active => inactive or active => + rewards
            if r.smartrent_status.blank? || r.smartrent_status == Smartrent::Resident::STATUS_ACTIVE
              if !live_in_properties.empty?
                if !smartrent_properties.empty?
                  r.update_attributes({
                    :smartrent_status => Smartrent::Resident::STATUS_ACTIVE,
                    :expiry_date => nil,
                    :disable_email_validation => true
                    })
                  create_monthly_rewards(r, smartrent_properties, period_start) if scheduled_run 
                else 
                  #Resident doesn't live in any smartrent property, set it's expiry to 2 year from the period start
                  expiry_date = (move_out_smartrent_properties.max_by{|rp| rp.move_out_date }.move_out_date rescue period_start) + 1.year
                  sr_status = period_start > expiry_date ? Smartrent::Resident::STATUS_EXPIRED : Smartrent::Resident::STATUS_INACTIVE
                  r.update_attributes({
                    :smartrent_status => sr_status,
                    :expiry_date => expiry_date,
                    :disable_email_validation => true
                    })
                end

              else # resident moved out, not live in any properties, set it's expiry to 60 days from the period start
                expiry_date = (move_out_smartrent_properties.max_by{|rp| rp.move_out_date }.move_out_date rescue period_start) + 2.months
                sr_status = period_start > expiry_date ? Smartrent::Resident::STATUS_EXPIRED : Smartrent::Resident::STATUS_INACTIVE
                r.update_attributes({
                  :smartrent_status => sr_status,
                  :expiry_date => expiry_date,
                  :disable_email_validation => true
                  })

              end
            end
            
            # inactive => expired or inactive => active
            if r.smartrent_status == Smartrent::Resident::STATUS_INACTIVE

              if smartrent_properties.empty?
                if period_start >= r.expiry_date
                  r.update_attributes(:smartrent_status => Smartrent::Resident::STATUS_EXPIRED)
                end

              else # resident moved in an eligible property
                r.update_attributes({
                  :smartrent_status => Smartrent::Resident::STATUS_ACTIVE,
                  :expiry_date => nil,
                  :disable_email_validation => true
                  })

                create_monthly_rewards(r, smartrent_properties, period_start) if scheduled_run
              end
            end

          rescue  Exception => e
            error_details = "#{e.class}: #{e}"
            error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
            # p "ERROR: #{error_details}"
            # p "[SmartRent] MonthlyStatusUpdater - FAILURE" if resident_id
            if !resident_id
              ::Notifier.system_message("[Smartrent::MonthlyStatusUpdater] FAILURE", "ERROR DETAILS: #{error_details}",
                ADMIN_EMAIL, {"from" => OPS_EMAIL}).deliver_now
            end
          end
        end
        
      end # /find in batch
      
        # p "[SmartRent] MonthlyStatusUpdater - SUCCESS" if resident_id
        Notifier.system_message("[SmartRent] MonthlyStatusUpdater - SUCCESS", "Executed at #{Time.now}", ADMIN_EMAIL).deliver_now if scheduled_run && !resident_id
      
    end # /perform
    
    def self.create_monthly_rewards(resident, smartrent_properties, period_start)
      smartrent_properties.each do |rp|

        # create monthly reward if not created for this month
        if resident.rewards.where(:resident_id => resident.id, :type_ => Reward::TYPE_MONTHLY_AWARDS, :period_start => [period_start, period_start.end_of_month]).count == 0
          if resident.total_rewards == 10000
            amount = 0
          else
            amount = Setting.monthly_award
          end
		  amount = 0 if check_month_days(rp,period_start)

          resident.rewards.create({
            :property_id => rp.property_id,
            :type_ => Reward::TYPE_MONTHLY_AWARDS,
            :period_start => period_start,
            :period_end => period_start.end_of_month,
            :amount => amount,
            :months_earned => 1
            })
        end
      end
    end

    def self.check_month_days(rp, period_start)
        if(rp.move_in_date.month == period_start.month && rp.move_in_date.day > 15 && rp.move_in_date.year == period_start.year)
            return true
        elsif(rp.move_out_date && rp.move_out_date == period_start.month && rp.move_out_date.day < 15 && rp.move_out_date.year == period_start.year)
            return true
        end
        return false 
    end
    
    def self.remove_duplicate_resident_properties(resident)
      resident.resident_properties.each do |rp1|
        resident.resident_properties.where.not(id: rp1.id).each do |rp2|
          if rp1.attributes.except("id", "created_at", "move_out_date", "updated_at", "status") == rp2.attributes.except("id", "created_at", "move_out_date", "updated_at", "status")
            resident_property = (rp1.move_out_date.nil? ? rp1 : rp2 )
            resident_property.destroy
          end
        end
      end
    end

    def self.set_status(r)
      period_start = Time.now.in_time_zone('Eastern Time (US & Canada)').beginning_of_month
      time = Time.now.in_time_zone('Eastern Time (US & Canada)')
      
      remove_duplicate_resident_properties(r)
      # get properties that the resident live in
      live_in_properties = r.resident_properties.select{|rp| rp.move_in_date <= period_start+15.days &&  (rp.move_out_date.blank? || rp.move_out_date > time) }
      #pp "live_in_properties:", live_in_properties
      
      # get smartrent eligible property
      smartrent_properties = live_in_properties.select{|rp| rp.property.eligible?(time) }
      #pp "smartrent_properties:", smartrent_properties
      
      move_out_smartrent_properties = r.resident_properties.select{|rp| rp.move_out_date && rp.move_out_date <= period_start.end_of_month && rp.property.eligible?(time) }
      #pp "move_out_smartrent_properties", move_out_smartrent_properties

      # active => inactive or still active
      if r.smartrent_status.blank? || r.smartrent_status == Smartrent::Resident::STATUS_ACTIVE

        if !live_in_properties.empty?

          if !smartrent_properties.empty?
            r.update_attributes({
              :smartrent_status => Smartrent::Resident::STATUS_ACTIVE,
              :expiry_date => nil,
              :disable_email_validation => true
              })
            
          else #Resident doesn't live in any smartrent property, set it's expiry to 2 year from the period start
            
            # don't mark the record as expired immediately, let's the monthly status update it
            # because the import create the unit sequentialy, we may not have all units at this calculation
            expiry_date = (move_out_smartrent_properties.max_by{|rp| rp.move_out_date }.move_out_date rescue period_start) + 1.year
            r.update_attributes({
              :smartrent_status => Smartrent::Resident::STATUS_INACTIVE,
              :expiry_date => expiry_date,
              :disable_email_validation => true
              })
          end

        else # resident moved out, not live in any properties
          
          # don't mark the record as expired immediately, let's the monthly status update it
          # because the import create the unit sequentialy, we may not have all units at this calculation
          expiry_date = (move_out_smartrent_properties.max_by{|rp| rp.move_out_date }.move_out_date rescue period_start) + 3.months
          r.update_attributes({
            :smartrent_status => Smartrent::Resident::STATUS_INACTIVE,
            :expiry_date => expiry_date,
            :disable_email_validation => true
            })
          
        end
      end

      # inactive => expired or inactive => active
      if r.smartrent_status == Smartrent::Resident::STATUS_INACTIVE

        if smartrent_properties.empty?
          if period_start >= r.expiry_date
            # don't mark the record as expired immediately, let's the monthly status update it
            # because the import create the unit sequentialy, we may not have all units at this calculation
            # r.update_attributes({
            #   :smartrent_status => Smartrent::Resident::STATUS_EXPIRED,
            #   :disable_email_validation => true
            # })
          end

        else # resident moved in an eligible property
          r.update_attributes({
            :smartrent_status => Smartrent::Resident::STATUS_ACTIVE,
            :expiry_date => nil,
            :disable_email_validation => true
            })

        end
      end
    end #/set_status
    
  end
end

