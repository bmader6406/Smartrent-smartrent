module Smartrent
  class Setting < ActiveRecord::Base
    #attr_accessible :key, :value
    validates_presence_of :key, :value
    validates_uniqueness_of :key, :case_sensitive => true

    after_save do
      if value.to_f >= 0
        rewards = []
        if key == "monthly_awards"
          rewards = Reward.where(:type_ => Reward.TYPE_MONTHLY_AWARDS)
        elsif key == "sign_up_bonus"
          rewards = Reward.where(:type_ => Reward.TYPE_SIGNUP_BONUS)
        end
        if rewards
          rewards.each do |reward|
            reward.update_attributes(:amount => value)
          end
        end
      end
    end

    def self.monthly_award
      setting = Setting.find_by_key("monthly_awards")
      if setting
        setting.value.to_f
      else
        0.0
      end
    end
    def self.sign_up_bonus
      setting = Setting.find_by_key("sign_up_bonus")
      if setting
        setting.value.to_f
      else
        0.0
      end
    end
  end
end
