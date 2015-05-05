module Smartrent
  class Reward < ActiveRecord::Base
    attr_accessible :amount, :period_end, :period_start, :property_id, :type, :resident_id
    belongs_to :resident
    belongs_to :property
    validates_presence_of :amount, :user_id, :property_id, :type, :period_start, :period_end
    validates_numericality_of :amount , :greater_than => 0
    validate :period_start_greater_than_period_end
    validate :valid_type

    def period_start_greater_than_period_end
      if period_start.present? and period_end.present?
        errors[:period_end] << "should be less than period start" if period_start > period_end
      end
    end

    def valid_type
      errors[:type] << "is invalid" if type < 0 or type > 3
    end

    def self.types
      {self.TYPE_SIGNUP_BONUS => "Sign Up", self.TYPE_MONTHLY_AWARDS => "Monthly Awards", self.TYPE_INITIAL_REWARD => "Initial Balance", self.TYPE_CHAMPION => "Champion"}
    end
    def self.TYPE_SIGNUP_BONUS
      0
    end
    def self.TYPE_MONTHLY_AWARDS
      1
    end
    def self.TYPE_INITIAL_REWARD
      2
    end
    def self.TYPE_CHAMPION
      3
    end
    def self.SIGNUP_BONUS
      350
    end
    def self.INITIAL_REWARD
      1200
    end
  end
end
