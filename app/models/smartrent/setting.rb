module Smartrent
  class Setting < ActiveRecord::Base
    
    validates :key, :value, :presence => true
    validates :key, :uniqueness => true

    after_save :update_rewards
    
    def self.sign_up_bonus
      Setting.find_by_key("sign_up_bonus").value.to_f rescue 100.0
    end
    
    def self.initial_reward
      Setting.find_by_key("initial_reward").value.to_f rescue 3500.0
    end
    
    def self.monthly_award
      Setting.find_by_key("monthly_awards").value.to_f rescue 350.0
    end
    
    private
    
      def update_rewards
        Resque.enqueue(Smartrent::SettingsAmountUpdater, id) if value_changed?
      end
      
  end
end
