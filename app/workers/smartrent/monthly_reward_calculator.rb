# https://docs.google.com/spreadsheets/d/1D3lSgqPxrUVIozZwXmgKyl3pqSW6_NYDUOtNoK5MGAU/edit#gid=1524520992

module Smartrent
  class MonthlyRewardCalculator

    def self.perform(resident_id, property_months_map)
      today = Date.today
      @@current_time = today.end_of_month

      @@time_seventhth_flats = @@current_time.change(day: 1, month: 02, year: 2018)
      @@seventh_flats_id = [12]

      resident = Smartrent::Resident.includes(:rewards).find_by_id resident_id

      property_months_map.each do |rp_id, months_earned|
        smartrent_resident_property = Smartrent::ResidentProperty.find rp_id
        months_earned.each_with_index do |month, index|
          str = month + "05"
          time = DateTime.parse(str)
          time = time.in_time_zone('Eastern Time (US & Canada)')
          period_start = time.beginning_of_month
          pp "start awarding : Property : #{smartrent_resident_property.property_id}  Unit : #{smartrent_resident_property.id}  period_start : #{period_start}"
          create_monthly_rewards(resident, smartrent_resident_property, period_start)
        end
      end

      if property_months_map.values.flatten.empty?
        destroy_monthly_awards_any_after_current_time(resident, @@current_time)
      end

      value = property_months_map.values.flatten.sort.first
      if value
        str = value + "05"
        time = DateTime.parse(str)
        time = time.in_time_zone('Eastern Time (US & Canada)')
        first_month_earned = time.beginning_of_month

        destroy_monthly_award_present_before_first_period_start(resident, first_month_earned)
      end

      value = property_months_map.values.flatten.sort.last
      if value
        str = value + "05"
        time = DateTime.parse(str)
        time = time.in_time_zone('Eastern Time (US & Canada)')
        last_month_earned = time.beginning_of_month

        destroy_monthly_award_present_after_last_period_start(resident, last_month_earned)
      end

      recalculate_monthly_rewards_if_any_missing(resident)
    end

    def self.create_monthly_rewards(resident, smartrent_resident_property, period_start)
      reward_exist = resident.rewards.where(
                                            type_:        Reward::TYPE_MONTHLY_AWARDS,
                                            period_start: period_start,
                                            period_end:   period_start.end_of_month
                                          ).last
      create_or_update_monthly_reward(resident, smartrent_resident_property, period_start, reward_exist)
    end

    def self.create_or_update_monthly_reward(r, rp, period_start, reward)
      amount = r.total_rewards >= 10000 ? 0 : Setting.monthly_award
      if reward
        pp "monthly_reward exist ===> #{r.email} ,, date: #{reward.period_start} ,, property: #{reward.property_id}"
        reward.update_attributes(
                                  property_id:    rp.property_id,
                                  period_start:   period_start,
                                  period_end:     period_start.end_of_month,
                                  amount:         amount
                                )
        pp "monthly_reward UPDATED ===> #{r.email} ,, date: #{period_start} ,, property: #{rp.property_id} ,, Amount: #{amount}"
      else
        r.rewards.create({
                          property_id:    rp.property_id,
                          type_:          Reward::TYPE_MONTHLY_AWARDS,
                          period_start:   period_start,
                          period_end:     period_start.end_of_month,
                          amount:         amount,
                          months_earned:  1
                        })
        pp "monthly_reward CREATED ===> #{r.email} ,, date: #{period_start} ,, property: #{rp.property_id} ,, Amount: #{amount}"
      end
    end

    def self.recalculate_monthly_rewards_if_any_missing(resident)
      monthly_rewards = resident.rewards.where(
                              type_: Reward::TYPE_MONTHLY_AWARDS
                            ).order('period_start asc')
      sign_up_reward = resident.rewards.where(
                              type_: Reward::TYPE_SIGNUP_BONUS
                            ).last.amount rescue 0
      initial_reward = resident.rewards.where(
                              type_: Reward::TYPE_INITIAL_REWARD
                            ).last.amount rescue 0

      amount = sign_up_reward + initial_reward

      monthly_rewards.each do |reward|
        if amount >= 10000
          reward.update_attributes(amount: 0)
        else
          reward.update_attributes(amount: Setting.monthly_award)
          amount += Setting.monthly_award
        end
      end
    end

    def self.destroy_monthly_award_present_before_first_period_start(resident, period_start)
      rewards = resident.rewards.where(
                                      'type_ = ? and period_start < ? and period_end < ?', 
                                      Reward::TYPE_MONTHLY_AWARDS, 
                                      period_start, 
                                      period_start.end_of_month
                                    )
      if rewards.present?
        pp "Before first period monthly award exist ===> #{resident.email}"
        rewards.each do |reward|
          pp "Before first period monthly award destoryed ===> start: #{reward.period_start} ,, end: #{reward.period_end}"
          reward.destroy
        end
      end
    end

    def self.destroy_monthly_award_present_after_last_period_start(resident, period_start)
      rewards = resident.rewards.where(
                                      'type_ = ? and period_start > ? and period_end > ?', 
                                      Reward::TYPE_MONTHLY_AWARDS, 
                                      period_start, 
                                      period_start.end_of_month
                                    )
      if rewards.present?
        pp "After last month period monthly award exist ===> #{resident.email}"
        rewards.each do |reward|
          pp "After last month period monthly award destoryed ===> start: #{reward.period_start} ,, end: #{reward.period_end}"
          reward.destroy
        end
      end
    end

    def self.destroy_monthly_awards_any_after_current_time(resident, time)
      rewards = resident.rewards.where(
                                      'type_ = ? and period_start > ? and period_end > ?', 
                                      Reward::TYPE_MONTHLY_AWARDS, 
                                      time.beginning_of_month, 
                                      time.end_of_month
                                    )

      seventh_flats_time = @@time_seventhth_flats
      seventh_flats_rewards = resident.rewards.where(
                                      'type_ = ? and property_id = ? and period_start > ? and period_end > ?', 
                                      Reward::TYPE_MONTHLY_AWARDS,
                                      @@seventh_flats_id.last,
                                      seventh_flats_time.beginning_of_month, 
                                      seventh_flats_time.end_of_month
                                    )
      if rewards.present?
        pp "monthly awards exist after current time: #{time} ===> #{resident.email}"
        rewards.each do |reward|
          pp "monthly award destoryed ===> start: #{reward.period_start} ,, end: #{reward.period_end}"
          reward.destroy
        end
      end

      if seventh_flats_rewards.present?
        pp "monthly awards exist after current time: #{seventh_flats_time} for Property 7th flats===> #{resident.email}"
        seventh_flats_rewards.each do |reward|
          pp "monthly award destoryed 7th flats property ===> start: #{reward.period_start} ,, end: #{reward.period_end}"
          reward.destroy
        end
      end
    end

  end
end

