module Smartrent
  class RewardCalculator

    def self.queue
      :crm_import
    end

    def self.perform(residents = [])
      @@current_time = DateTime.now - 1.month
      calculate_rewards(residents)
    end

    def self.calculate_rewards(residents = [])
      residents.each do |r|
        pp "taken resident ===> #{r.email}"

        pp "calling signup bonus reward ===> #{r.email}"
        create_sign_up_bonus_reward(r)

        reward_start_time = @@current_time.change(day: 25, month: 02, year: 2016)
        
        pp "calling initial reward ===> #{r.email}"
        create_initial_rewards(r, reward_start_time)

        time = @@current_time.change(day: 1, month: 03, year: 2016) #smartrent_program begins

				property_months_map = smartrent_months_to_be_awarded(r.resident_properties, time)

				pp "calling monthly reward calculator ===> #{r.email} ,, property_months_map: #{property_months_map}}"
				Smartrent::MonthlyRewardCalculator.perform(r.id, property_months_map)

        pp "calling smartrent status worker ===> #{r.email}"
        Smartrent::ChangeSmartrentStatus.perform(r.id)

        pp "calling expiry reward settig method ===> #{r.email} ,, if smartrent_status is EXPIRED"
        set_expiry_reward(r)

        pp "finished processing resident ===> #{r.email}"

      end
    end

    def self.create_sign_up_bonus_reward(r)
      resident_property = smartrent_properties(r).min_by{|rp| rp.move_in_date }
      sign_up_reward = r.rewards.where(type_: 1).last
      if resident_property
	      if sign_up_reward
	      	pp "sign_up_reward exist ===> #{r.email} ,, SIGNUP_BONUS_date: #{sign_up_reward.period_start}"
	      	sign_up_reward.update_attributes(
	      																		property_id: 		resident_property.property_id,
				                                    resident_id: 		r.id,
				                                    period_start: 	resident_property.move_in_date.beginning_of_month
	      																	)
	      else
	        Smartrent::Reward.create!({
	                                    property_id: 		resident_property.property_id,
	                                    resident_id: 		r.id,
	                                    amount: 				Smartrent::Setting.sign_up_bonus,
	                                    type_: 					Reward::TYPE_SIGNUP_BONUS,
	                                    period_start: 	resident_property.move_in_date.beginning_of_month
	        													})
	        pp "sign_up_reward created ===> #{r.email} ,, SIGNUP_BONUS_date: #{resident_property.move_in_date.beginning_of_month}"
	      end
	    end
    end

    def self.create_initial_rewards(r, reward_start_time)
    	resident_properties = smartrent_properties(r).select{|rp| 
    																								rp.move_in_date < reward_start_time
    																							}
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
      	first_move_in = rp.move_in_date
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

    def self.smartrent_months_to_be_awarded(resident_properties, program_start_time)
    	eligible_months = []
    	property_months_map = {}
    	resident_properties.each do |rp|
    		if rp.property.is_smartrent
    			eligible_months = get_smartrent_eligible_months(rp, program_start_time)
    			pp "Smartrent Eligible months ==== > #{eligible_months}"
    			already_added_months = property_months_map.values.flatten & eligible_months rescue []
    			eligible_months = eligible_months - already_added_months rescue []
    			property_months_map[rp.id] = eligible_months.uniq
    		end
    	end
    	property_months_map
    end

    def self.months_to_be_awarded(resident_properties, reward_start_time)
      eligible_months = []
      resident_properties.each do |rp|
        if rp.property.is_smartrent
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
    				get_months_between(program_start_time, rp.move_out_date)
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
      																			property_id: 		fetch_property_id(rps),
  																					amount: 				amount.nil? ? 0 : amount,
  																					period_start: 	move_in,
                              							period_end: 		last_earned,
                              							months_earned: 	months_earned.count
    																			)
      		pp "initial_reward updated ===> Amount: #{amount.nil? ? 0 : amount} ,, months_earned: #{months_earned.count}"
      	else
      		Smartrent::Reward.create!({
                                      property_id: 		fetch_property_id(rps),
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
    	smartrent_properties = r.resident_properties.select{|rp| rp.property.is_smartrent }
    end

    def self.fetch_property_id(rp)
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
