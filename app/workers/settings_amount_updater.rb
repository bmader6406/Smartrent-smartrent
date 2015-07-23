  class SettingsAmountUpdater
    @queue = :settings_amount_updater
    def self.perform(settings_id)
      setting = Smartrent::Setting.find(settings_id)
      if setting.value.to_f >= 0
        rewards = []
        if setting.key == "monthly_awards"
          rewards = Reward.where(:type_ => Reward.TYPE_MONTHLY_AWARDS)
        elsif setting.key == "sign_up_bonus"
          rewards = Reward.where(:type_ => Reward.TYPE_SIGNUP_BONUS)
        end
        if rewards
          rewards.each do |reward|
            reward.update_attributes(:amount => setting.value)
          end
        end
      end
    end
  end
