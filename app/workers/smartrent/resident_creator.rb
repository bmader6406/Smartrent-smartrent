module Smartrent
  class ResidentCreator
    def self.queue
      :crm_import
    end
  
    def self.perform(resident_id, unit_id)
      resident = ::Resident.find(resident_id)
      unit = resident.units.find(unit_id)

      create_smartrent_resident(resident, unit)
    end
    
    def self.create_smartrent_resident(resident, unit, set_status = true, disable_rewards = false)
      # Initialize by email is better than crm_resident_id
      # because the id "link" will be broken when the user do the full upload, result in duplicated sr resident
      sr = Smartrent::Resident.find_or_initialize_by(email: resident.email)
      sr.email = resident.email
      sr.first_name = resident.first_name
      sr.last_name = resident.last_name
      sr.crm_resident_id = resident.id.to_i # link smartrent resident with crm resident
      # set initial status for validation
      sr.smartrent_status = Smartrent::Resident.SMARTRENT_STATUS_ACTIVE if sr.smartrent_status.blank?
      sr.save(:validate => false)
      
      sr_property = sr.resident_properties.find_or_initialize_by(property_id: unit.property_id, unit_code: unit.unit_code)
      sr_property.status = unit.status
      sr_property.move_in_date = unit.move_in
      sr_property.move_out_date = unit.move_out
      sr_property.disable_rewards = disable_rewards
      sr_property.save
      
      if sr_property.status == Smartrent::ResidentProperty.STATUS_CURRENT
        sr.update_attributes(:current_property_id => unit.property_id, :current_unit_id => unit.unit_id)
      end
      
      Smartrent::MonthlyStatusUpdater.set_status(sr) if set_status
    end
    
    def self.delete_and_create_all_residents
      # for *manual* run in rails console after the first full yardi file import
      # it will reset the smartrent resident database (account, rewards)
      # This task should be only run ONE TIME to create the smartrent database
      
      pp "delete_and_create_all_residents start: #{Time.now}"
      
      pp "total Smartrent::Resident: #{Smartrent::ResidentProperty.count}"
      Smartrent::Resident.delete_all
      
      pp "total Smartrent::ResidentProperty: #{Smartrent::ResidentProperty.count}"
      Smartrent::ResidentProperty.delete_all
      
      pp "total Smartrent::Reward: #{Smartrent::Reward.count}"
      Smartrent::Reward.delete_all
      
      ActiveRecord::Base.connection.execute("ALTER TABLE smartrent_residents AUTO_INCREMENT = 1;")
      ActiveRecord::Base.connection.execute("ALTER TABLE smartrent_resident_properties AUTO_INCREMENT = 1;")
      ActiveRecord::Base.connection.execute("ALTER TABLE smartrent_rewards AUTO_INCREMENT = 1;")
      
      total = 0
      smartrent_dict = {}
      
      Property.all.each do |prop|
        smartrent_dict[prop.id] = prop.is_smartrent?
      end
      
      ::Resident.each do |r|
        r.units.each do |u|
          if smartrent_dict[u.property_id.to_i] && !u.roommate? && u.move_in && u.move_in.to_time <= Time.now
            total += 1
            pp "total: #{total}, r._id: #{r._id}, u._id.to_s: #{u._id.to_s}"
            create_smartrent_resident(r, u, false, true)
          end
        end
      end
      
      # create initial and sign up rewards
      Smartrent::Resident.includes(:resident_properties => :property).find_in_batches do |residents|
        residents.each do |sr|
          create_initial_signup_rewards(sr)
        end
      end
      
      # set smartrent status here to speed up this task
      MonthlyStatusUpdater.perform(Time.now.prev_month, false)
      pp "delete_and_create_all_residents done: #{Time.now}"
    end
    
    def self.create_initial_signup_rewards(sr)
      now = Time.now
      
      first_rp = nil
      first_move_in = nil
      
      eligible_properties = []
      
      sr.resident_properties.each do |rp|
        if rp.property.eligible?
          first_rp = rp if !first_rp
          first_move_in = rp.move_in_date if !first_move_in
            
          if rp.move_in_date <= first_move_in
            first_rp = rp
            first_move_in = rp.move_in_date
          end
          
          eligible_properties << rp
        end
      end
      
      initial_amount = 0
      months_earned = 0
      
      eligible_properties.each do |rp|
        if rp.move_out_date.blank? || rp.move_out_date && rp.move_out_date > now
          months_earned += (Time.now.difference_in_months(rp.move_in_date) rescue 0)
          #pp "months_earned: #{months_earned}, #{Time.now.difference_in_months(rp.move_in_date)}, #{rp.move_in_date}"
          
        else
          months_earned += (rp.move_out_date.difference_in_months(rp.move_in_date) rescue 0)
          #pp "months_earned2: #{months_earned}, #{rp.move_out_date.difference_in_months(rp.move_in_date)}, #{rp.move_in_date}, #{rp.move_out_date}"
          
          # count incomplete month for moved out resident
          months_earned += 1
        end
      end
      
      if months_earned >= 1
        initial_amount = Smartrent::Setting.monthly_award*months_earned
        initial_amount = 9900 if initial_amount > 9900 # 100 will be added by sign up bonus
      end
      
      pp "#{sr.id}, #{sr.email}, months_earned: #{months_earned}, initial_amount: #{initial_amount}"
      
      if !eligible_properties.empty?
        Smartrent::Reward.create!({
          :property_id => first_rp.property_id,
          :resident_id => sr.id,
          :amount => initial_amount,
          :type_ => Reward.TYPE_INITIAL_REWARD,
          :period_start => first_move_in,
          :months_earned => months_earned
        })
        
        Smartrent::Reward.create!({
          :property_id => first_rp.id,
          :resident_id => sr.id,
          :amount => Smartrent::Setting.sign_up_bonus,
          :type_ => Reward.TYPE_SIGNUP_BONUS,
          :period_start => first_move_in
        })
      end
      
    end
    
  end
end