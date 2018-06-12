# https://docs.google.com/spreadsheets/d/1D3lSgqPxrUVIozZwXmgKyl3pqSW6_NYDUOtNoK5MGAU/edit#gid=1524520992

module Smartrent
  class MonthlyRewardCalculator

    def self.perform(resident_id, property_months_map)
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

      value = property_months_map.values.flatten.sort.first
      if value
        str = value + "05"
        time = DateTime.parse(str)
        time = time.in_time_zone('Eastern Time (US & Canada)')
        first_month_earned = time.beginning_of_month

        destroy_monthly_award_present_before_first_period_start(resident, first_month_earned)
      end
    end

    def self.create_monthly_rewards(resident, smartrent_resident_property, period_start)
      reward_exist = resident.rewards.where(
                                            type_:        Reward::TYPE_MONTHLY_AWARDS,
                                            period_start: period_start,
                                            period_end:   period_start.end_of_month
                                          )
      if reward_exist.empty?
        amount = resident.total_rewards >= 10000 ? 0 : Setting.monthly_award
        resident.rewards.create({
                                  property_id:    smartrent_resident_property.property_id,
                                  type_:          Reward::TYPE_MONTHLY_AWARDS,
                                  period_start:   period_start,
                                  period_end:     period_start.end_of_month,
                                  amount:         amount,
                                  months_earned:  1
                                })
      end
    end

    def self.destroy_monthly_award_present_before_first_period_start(resident, period_start)
      rewards = resident.rewards.where(
                                      'type_ = ? and period_start < ? and period_end < ?', 
                                      Reward::TYPE_MONTHLY_AWARDS, period_start, period_start.end_of_month
                                    )
      if rewards.present?
        pp "Before first period monthly award exist ===> #{resident.email}"
        rewards.each do |reward|
          reward.destroy
          pp "Before first period monthly award destoryed ===> start: #{reward.period_start} ,, end: #{reward.period_end}"
        end
      end
    end

  end
end

