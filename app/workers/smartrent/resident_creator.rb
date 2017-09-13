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
      
      # check test accounts
      #pp "resident.email: #{resident.email}"
      test_account = Smartrent::TestAccount.find_by_origin_email(resident.email)
      
      if test_account
        pp "found test_account: #{test_account.origin_email}, #{test_account.new_email}"
        sr = Smartrent::Resident.find_or_initialize_by(email: test_account.new_email)
      else
        sr = Smartrent::Resident.find_or_initialize_by(email: resident.email)
      end
      
      sr.first_name = resident.first_name
      sr.last_name = resident.last_name
      sr.crm_resident_id = resident.id.to_i # link smartrent resident with crm resident
      # set initial status for validation
      sr.smartrent_status = Smartrent::Resident::STATUS_ACTIVE if sr.smartrent_status.blank?
      sr.save(:validate => false)
      
      sr_property = sr.resident_properties.find_or_initialize_by(property_id: unit.property_id, unit_code: unit.unit_code)
      sr_property.status = unit.status
      sr_property.move_in_date = unit.move_in
      sr_property.move_out_date = unit.move_out
      sr_property.disable_rewards = disable_rewards
      sr_property.save
      
      if sr_property.status == Smartrent::ResidentProperty::STATUS_CURRENT
        sr.update_attributes(:current_property_id => unit.property_id, :current_unit_id => unit.unit_id, :disable_email_validation => true)
      end
      
      Smartrent::MonthlyStatusUpdater.set_status(sr) if set_status
    end
    
    def self.delete_and_create_all_residents(cal_time = Time.now)
      # for *manual* run in rails console after the first full yardi file import
      # it will reset the smartrent resident database (account, rewards)
      # This task should be only run ONE TIME to create the smartrent database
      now = Time.now
      
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
          if smartrent_dict[u.property_id.to_i] && !u.roommate? && u.move_in && u.move_in.to_time <= now
            total += 1
            pp "total: #{total}, r._id: #{r._id}, u._id.to_s: #{u._id.to_s}"
            create_smartrent_resident(r, u, false, true)
          end
        end
      end
      
      # create initial and sign up rewards
      Smartrent::Resident.includes(:resident_properties => :property).find_in_batches do |residents|
        residents.each do |sr|
          create_initial_signup_rewards(sr, cal_time)
        end
      end
      
      # set smartrent status here to speed up this task
      MonthlyStatusUpdater.perform(cal_time.prev_month, false)
      pp "delete_and_create_all_residents done: #{Time.now}"
    end
    
    def self.create_initial_signup_rewards(sr, cal_time = DateTime.now)
      first_rp = nil
      first_move_in = nil
      
      eligible_properties = []
      rps = sr.resident_properties.order('move_in_date ASC')
      rps.each do |rp|
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
      months_earned = []
      balance_days = 0 #if move out of previous property is 10th FEB 2016 and move in of next property is 20th Feb 2016 that month need to be calculated... hence balance_days is used
    

      eligible_properties.each do |rp|
        t = rp.move_in_date.clone
        move_in = t.in_time_zone("EST").change(:day=>t.strftime("%d").to_i,:hour=>0)
        t = rp.move_out_date.clone rescue cal_time
        move_out = t.in_time_zone("EST").change(:day=>t.strftime("%d").to_i,:hour=>0)
        if rp.move_out_date.blank? || rp.move_out_date && rp.move_out_date > cal_time
          arr,balance_days = collect_months(move_in, cal_time,balance_days)
          months_earned << arr
          
          pp ">> months_earned: #{arr.length}, #{move_in}, #{cal_time},balance:#{balance_days}" #, arr
          
          
        else
          arr,balance_days = collect_months(move_in, move_out,balance_days)
          months_earned << arr
          pp ">> months_earned2: #{arr.length}, #{move_in}, #{move_out},balance:#{balance_days}" #, arr
          
        end
      end
      
      months_earned = months_earned.flatten.uniq.sort
      
      if months_earned.length >= 1
        initial_amount = Smartrent::Setting.monthly_award*months_earned.length
        initial_amount = 9900 if initial_amount > 9900 # 100 will be added by sign up bonus
      end
      p months_earned
      pp "FINAL: #{sr.id}, #{sr.email}, months_earned: #{months_earned.length}, initial_amount: #{initial_amount}, first_rp.property_id #{first_rp.property_id}" #, months_earned
      
      if !eligible_properties.empty?
        Smartrent::Reward.create!({
          :property_id => first_rp.property_id,
          :resident_id => sr.id,
          :amount => initial_amount,
          :type_ => Reward::TYPE_INITIAL_REWARD,
          :period_start => first_move_in,
          :period_end => first_move_in.advance(months: months_earned.length),
          :months_earned => months_earned.length
        })
        
        Smartrent::Reward.create!({
          :property_id => first_rp.property_id,
          :resident_id => sr.id,
          :amount => Smartrent::Setting.sign_up_bonus,
          :type_ => Reward::TYPE_SIGNUP_BONUS,
          :period_start => first_move_in
        })
      end
      
    end
    
    def self.collect_months(t1, t2, pre_balance_days=0)
      begin
        return [[],0] if t1 > t2
        t1 = t1.clone.in_time_zone("EST").change(:day=>t1.day,:month=>t1.month,:year=>t1.year,:hour=>0)
        # t1 = t1.end_of_month
        t2 = t2.clone.in_time_zone("EST").change(:day=>t2.day,:month=>t2.month,:year=>t2.year,:hour=>0)
        # t2 = t2.beginning_of_month
        
        # t1.end_of_month, t2.beginning_of_month
        # this will make sure we don't count "2015/03" if t1 is 2015/01/15, t2 is  2015/03/20
        # we don't count "2015/03" if t1 is 2015/03/15, t2 is  2015/03/20 or 2015/03/01, t2 is  2015/03/31
        months = []
        
        # TODO: if move in date is 16th and move out is next month14th... one month should be considered
        # This is already in affect. Need to recheck

        if (t1.beginning_of_month == t2.beginning_of_month)
          if ((t2.day- t1.day) >= 15) #TODO: replace with ELIGIBLE_DATE environment variable
            months << t1.strftime("%Y/%m")
          end
        elsif (t1.day-pre_balance_days <= 15) #TODO: replace with ELIGIBLE_DATE environment variable
          months << t1.strftime("%Y/%m")
        end
        t1 += 1.month
        t1 = t1.beginning_of_month
        balance_days = 0
        while t1 < t2
          if (t1 == t2.beginning_of_month) && (t2.day < 15) #TODO: replace with ELIGIBLE_DATE environment variable
            t1 += 1.month
            balance_days = t2.day
            break
          end
          # if t1 < t2
          months << t1.strftime("%Y/%m")
          # end
          t1 += 1.month
        end
        
        months = months.uniq.sort
        #pp "total: #{months.length}", months
        
        return months,balance_days
      rescue
        [[],0]
      end
    end
    
  end
end