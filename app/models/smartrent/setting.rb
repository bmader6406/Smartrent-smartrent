module Smartrent
  class Setting < ActiveRecord::Base
    #attr_accessible :key, :value
    validates_presence_of :key, :value
    validates_uniqueness_of :key, :case_sensitive => true

    after_save do
      Resque.enqueue(::SettingsAmountUpdater, id)
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
