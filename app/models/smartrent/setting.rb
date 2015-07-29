module Smartrent
  class Setting < ActiveRecord::Base
    
    validates :key, :value, :presence => true
    validates :key, :uniqueness => true

    after_save :update_rewards

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
    
    private
    
      def update_rewards
        Resque.enqueue(::SettingsAmountUpdater, id)
      end
  end
end
