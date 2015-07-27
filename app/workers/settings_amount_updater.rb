class SettingsAmountUpdater
  @queue = :settings_amount_updater
  
  def self.perform(settings_id)
    setting = Smartrent::Setting.find(settings_id)
    
    if setting.value.to_f >= 0
      if setting.key == "monthly_awards"
        Reward.where(:type_ => Reward.TYPE_MONTHLY_AWARDS).update_all(:amount => setting.value)
        
      elsif setting.key == "sign_up_bonus"
        Reward.where(:type_ => Reward.TYPE_SIGNUP_BONUS).update_all(:amount => setting.value)
      end
    end
  end
  
end
