module Smartrent
  class RewardCalculator

    def self.queue
      :crm_import
    end

    def self.perform(time = nil, residents = [])
      @@today = time 
      @@today = Date.today - 1.month if @@today.nil?
      @@current_time = @@today.end_of_month

      @@time_seventhth_flats = @@current_time.change(day: 1, month: 02, year: 2018)
      @@seventh_flats_id = [12]

      @@time_monument_central = @@current_time.change(day: 1, month: 04, year: 2018)
      @@monument_central_ids = [394,451]

      @@time_apollo = @@current_time.change(day: 1, month: 02, year: 2018)
      @@apollo_id = [196]

      calculate_rewards(residents, time.nil?)
    end

    def self.calculate_rewards(residents = [], schedule_run = true)
      residents.each do |r|
        pp "taken resident ===> #{r.email}"

        pp "calling signup bonus reward ===> #{r.email}"
        create_sign_up_bonus_reward(r)

        time = @@current_time.change(day: 1, month: 03, year: 2016) #smartrent_program begins
        
        pp "calling initial reward ===> #{r.email}"
        create_initial_rewards(r, time)

				property_months_map = smartrent_months_to_be_awarded(r, time)

				pp "calling monthly reward calculator ===> #{r.email} ,, property_months_map: #{property_months_map}}"
				Smartrent::MonthlyRewardCalculator.perform(r.id, property_months_map)

        pp "calling smartrent status worker ===> #{r.email}"
        Smartrent::ChangeSmartrentStatus.perform(r.id) if schedule_run

        r.reload
        pp "calling expiry reward settig method ===> #{r.email} ,, if smartrent_status is EXPIRED"
        set_expiry_reward(r) if schedule_run

        r.reload
        pp "updating balance ===> #{r.email} ,, current: #{r.balance}"
        r.update_attributes(balance: r.total_rewards)

        pp "finished processing resident ===> #{r.email}"

      end
    end

    def self.create_sign_up_bonus_reward(r)
      resident_property = fetch_min_move_in_smartrent_property(r)
      sign_up_reward = r.rewards.where(type_: 1).last
      if resident_property
	      if sign_up_reward
	      	pp "sign_up_reward exist ===> #{r.email} ,, property: #{resident_property.property_id} ,, SIGNUP_BONUS_date: #{sign_up_reward.period_start}"
	      	sign_up_reward.update_attributes(
	      																		property_id: 		resident_property.property_id,
				                                    resident_id: 		r.id,
				                                    period_start: 	resident_property.move_in_date.beginning_of_month
	      																	)
          puts "sign_up_reward updated ===> #{r.email} ,,  property: #{resident_property.property_id} ,, SIGNUP_BONUS_date: #{sign_up_reward.period_start}"
	      else
	        Smartrent::Reward.create!({
	                                    property_id: 		resident_property.property_id,
	                                    resident_id: 		r.id,
	                                    amount: 				Smartrent::Setting.sign_up_bonus,
	                                    type_: 					Reward::TYPE_SIGNUP_BONUS,
	                                    period_start: 	resident_property.move_in_date.beginning_of_month
	        													})
	        pp "sign_up_reward created ===> #{r.email} ,, property: #{resident_property.property_id} ,, SIGNUP_BONUS_date: #{resident_property.move_in_date.beginning_of_month}"
	      end
      else
        if sign_up_reward
          pp "destoryed singup reward if exist"
          sign_up_reward.destroy
        end
	    end
    end

    def self.create_initial_rewards(r, reward_start_time)
    	resident_properties = smartrent_properties(r).sort_by {|rp| rp.move_in_date}

      earned_months = months_to_be_awarded(resident_properties, reward_start_time)

    	pp "creating initial rewards ===> ,, months_earned <> with_count: #{earned_months} <> #{earned_months.count}"
      initial_amount = Smartrent::Setting.monthly_award*earned_months.count
      initial_amount = 9900 if initial_amount > 9900 # 100 will be added by sign up bonus

      last_earned_month = nil
      if earned_months.count > 0
	      last_month = earned_months.last
	      str = last_month + "01"
	      last_earned_month = DateTime.parse(str).end_of_month
	    end

      rp = resident_properties.min_by{|rp| rp.move_in_date }
      if rp.nil?
      	sign_up_reward = r.rewards.where(type_: 1).last
      	first_move_in = sign_up_reward.period_start rescue nil
      	last_earned_month = sign_up_reward.period_end rescue nil
      else
      	first_move_in = rp.move_in_date.beginning_of_month
      end

      intial_reward_exist = r.rewards.where(type_: Reward::TYPE_INITIAL_REWARD).last
      create_or_update_initial_reward(
      																r, resident_properties,
      																first_move_in, earned_months,
      																last_earned_month, initial_amount,
      																intial_reward_exist
      															)
    end

    def self.set_expiry_reward(r)
    	if r.smartrent_status == Smartrent::Resident::STATUS_EXPIRED
    		expiry_reward_exist = r.rewards.where(type_: Reward::TYPE_EXPIRED).last
    		expiry_amount = resident_expiry_amount(r)
    		if expiry_reward_exist
    			pp "expiry reward exist ===> #{r.email} ,, Amount: #{expiry_reward_exist.amount}"
    			pp "expiry reward updated ===> ===> #{r.email} ,, Amount: #{-expiry_amount}"
    			expiry_reward_exist.update_attributes(
    																						amount: -expiry_amount, 
    																						period_start: @@current_time.beginning_of_month
    																					)
    		else
    			pp "creating expiry reward ===> #{r.email} ,, Amount: #{-expiry_amount}"
	    		Smartrent::Reward.create!({
	                                    property_id: 		nil,
	                                    resident_id: 		r.id,
	                                    amount:         -expiry_amount,
	                                    type_: 					Reward::TYPE_EXPIRED,
	                                    period_start: 	r.expiry_date.beginning_of_month,
	                                    period_end: 		nil,
	                                    months_earned: 	0
		      													})
	    	end
	    else
	    	# expiry reward may exist before for non expired residents
	    	# delete the expiry reward
	    	expiry_reward_exist = r.rewards.where(type_: Reward::TYPE_EXPIRED).last
	    	if expiry_reward_exist
	    		pp "expiry reward exist ===> #{r.email} ,, Amount: #{expiry_reward_exist.amount}"
	    		pp "DELETE expiry reward ===> #{r.email}"
	    		expiry_reward_exist.destroy
	    	end
	    end
    end

    def self.resident_expiry_amount(r)
    	r.rewards.where(type_: [0,1,2,3]).collect(&:amount).inject(:+)
    end

    def self.smartrent_months_to_be_awarded(r, program_start_time)
    	eligible_months = []
    	property_months_map = {}
      not_expired_rps = []

      rps = smartrent_properties(r).sort_by {|rp| rp.move_in_date}

      (rps.length-1).times do |i|
        if rps[i+1].move_in_date && rps[i].move_out_date
          if ((rps[i+1].move_in_date - rps[i].move_out_date)/365).to_i >= 2
            next
          else
            not_expired_rps << rps[i]
          end
        else
          not_expired_rps << rps[i]
        end
      end

      not_expired_rps << rps.last if last_rp_not_expired_with_current_time?(rps.last)

      not_expired_rps.uniq.each do |rp|
        start_time = calculate_start_time_from_property(rp, program_start_time)
        eligible_months = get_smartrent_eligible_months(rp, start_time)
        pp "Smartrent Eligible months ==== > #{eligible_months}"
        already_added_months = property_months_map.values.flatten & eligible_months rescue []
        eligible_months = eligible_months - already_added_months rescue []
        property_months_map[rp.id] = eligible_months.uniq
      end

    	property_months_map
    end

    def self.calculate_start_time_from_property(rp, given_time)
      if @@monument_central_ids.include? rp.property_id
        @@time_monument_central
      elsif @@apollo_id.include? rp.property_id
        @@time_apollo
      else
        given_time
      end
    end

    def self.months_to_be_awarded(smartrent_properties, reward_start_time)
      eligible_months = []
      not_expired_rps = []
      rps = smartrent_properties

      (rps.length-1).times do |i|
        if rps[i+1].move_in_date && rps[i].move_out_date
          if ((rps[i+1].move_in_date - rps[i].move_out_date)/365).to_i >= 2
            next
          else
            not_expired_rps << rps[i]
          end
        else
          not_expired_rps << rps[i]
        end
      end

      if rps.count > 1
        last_two_rps = rps.last(2)
        if last_two_rps[1].move_in_date && last_two_rps[0].move_out_date
          if ((last_two_rps[1].move_in_date - last_two_rps[0].move_out_date)/365).to_i >= 2
            not_expired_rps = []
            pp "Intital reward expired for email: - #{rps[0].resident.email}"
          end
        end
      end

      not_expired_rps << rps.last if last_rp_not_expired_with_current_time?(rps.last)

      # initial reward is only applicable if move_in_date is before reward_start_time
      less_than_reward_start_time = not_expired_rps.select{|rp| 
                                                      rp.move_in_date < reward_start_time
                                                    }
      if less_than_reward_start_time.present?
        less_than_reward_start_time.uniq.each do |rp|
          eligible_months << get_eligible_months(rp, reward_start_time)
        end
      end

      eligible_months.flatten.uniq.sort
    end

    def self.get_eligible_months(rp, reward_start_time)
      if rp.move_out_date.nil? || rp.move_out_date >= reward_start_time
        get_months_between(rp.move_in_date, reward_start_time)
      else
        if rp.move_out_date && rp.move_out_date < reward_start_time
          get_months_between(rp.move_in_date, rp.move_out_date) #move_out_date should be greater than move_in_date
        end
      end
    end

    def self.get_smartrent_eligible_months(rp, program_start_time)
      if @@seventh_flats_id.include? rp.property_id
        @@current_time = @@time_seventhth_flats
      else
        @@current_time = @@today.end_of_month
      end
    	if rp.move_in_date > program_start_time
    		if rp.move_out_date.nil? || rp.move_out_date >= @@current_time
    			get_months_between(rp.move_in_date, @@current_time)
    		else
    			if rp.move_out_date
    				get_months_between(rp.move_in_date, rp.move_out_date)
    			end
    		end
    	else
    		if rp.move_out_date.nil? 
    			get_months_between(program_start_time, @@current_time)
    		else
    			if rp.move_out_date >= program_start_time
            if rp.move_out_date >= @@current_time
    				  get_months_between(program_start_time, @@current_time)
            else
              get_months_between(program_start_time, rp.move_out_date)
            end
    			else
            []
          end
    		end
    	end
    end

    def self.get_months_between(reward_end_time, reward_start_time)
      (reward_end_time..reward_start_time).map{ |m| m.strftime('%Y%m') }.uniq
    end

    def self.smartrent_resident_properties_having_max_move_out_date(resident_properties)
    	smartrent_properties = resident_properties.select{|rp| rp.property.is_smartrent }
    	current_live_in_properties = smartrent_properties.select{|rp| rp.move_out_date.nil?}
    	if current_live_in_properties.present?
    	  current_live_in_properties
    	else
    		[smartrent_properties.max_by{|rp| rp.move_out_date }].flatten
    	end
    end

    def self.smartrent_resident_properties_having_min_move_in_date(resident_properties)
    	smartrent_properties = resident_properties.select{|rp| rp.property.is_smartrent }
    	[smartrent_properties.min_by{|rp| rp.move_in_date }].flatten
    end

    def self.create_or_update_initial_reward(r = nil, rps = nil, move_in = nil, months_earned = [], last_earned = nil, amount = nil, initial_reward = nil)
    	if move_in
        if initial_reward
      		pp "initial_reward exist ===> Amount: #{initial_reward.amount} ,, months_earned: #{initial_reward.months_earned}"
      		initial_reward.update_attributes!(
      																			property_id: 		fetch_property_id(rps, months_earned),
  																					amount: 				amount.nil? ? 0 : amount,
  																					period_start: 	move_in,
                              							period_end: 		last_earned,
                              							months_earned: 	months_earned.count
    																			)
      		pp "initial_reward updated ===> Amount: #{amount.nil? ? 0 : amount} ,, months_earned: #{months_earned.count} ,, Property: #{fetch_property_id(rps, months_earned)}"
      	else
      		Smartrent::Reward.create!({
                                      property_id: 		fetch_property_id(rps, months_earned),
                                      resident_id: 		fetch_resident_id(r),
                                      amount: 				amount.nil? ? 0 : amount,
                                      type_: 					Reward::TYPE_INITIAL_REWARD,
                                      period_start: 	move_in,
                                      period_end: 		last_earned,
                                      months_earned: 	months_earned.count
  	        												})
      		pp "created new intial reward ==> Amount: #{amount.nil? ? 0 : amount} ,, months_earned: #{months_earned.count}"
      	end
      end
    end

    def self.smartrent_properties(r)
    	smartrent_properties = r.resident_properties.select{|rp| rp.property.is_smartrent || rp.property_id == @@seventh_flats_id.last}
    end

    def self.fetch_min_move_in_smartrent_property(r)
      rps = smartrent_properties(r).sort_by {|rp| rp.move_in_date}
      #find min_move_in rp witch is not expired

      min_move_in_rp = nil
      not_expired_rps = []

      (rps.length-1).times do |i|
        if rps[i+1].move_in_date && rps[i].move_out_date
          if ((rps[i+1].move_in_date - rps[i].move_out_date)/365).to_i >=2
            next
          else
            not_expired_rps << rps[i]
          end
        else
          not_expired_rps << rps[i]
        end
      end

      not_expired_rps << rps.last  if last_rp_not_expired_with_current_time?(rps.last) && rp_move_in_date_not_after_current_time?(rps.last)

      min_move_in_rp = not_expired_rps.uniq.min_by{|rp| rp.move_in_date } if not_expired_rps.present?
    end

    def self.resident_property_expired?(rp, time)
      rp.move_out_date && rp.move_out_date + 2.years < time
    end

    def self.last_rp_not_expired_with_current_time?(rp)
      if rp
        if @@seventh_flats_id.include? rp.property_id
          @@current_time = @@time_seventhth_flats
        else
          @@current_time = @@today.end_of_month
        end
        if rp.move_out_date.nil?
          return true
        else
          rp.move_out_date + 2.years > @@current_time
        end
      else
        return false
      end
    end

    def self.rp_move_in_date_not_after_current_time?(rp)
      if rp
        if @@seventh_flats_id.include? rp.property_id
          @@current_time = @@time_seventhth_flats
        else
          @@current_time = @@today.end_of_month
        end
        if rp.move_in_date <= @@current_time
          return true
        else
          false
        end
      else
        return false
      end
    end

    def self.move_in_after_current_time(rp, time)
      rp.move_in_date && rp.move_in_date > time
    end

    def self.fetch_property_id(rp, months_earned)
      return nil if months_earned.empty?
    	if rp.present?
    		rp.first.property_id
    	else
    		nil
    	end
    end

    def self.fetch_resident_id(r)
    	if r
    		r.id
    	else
    		nil
    	end
    end

  end
end
