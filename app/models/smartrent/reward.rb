module Smartrent
  class Reward < ActiveRecord::Base
    belongs_to :resident
    belongs_to :property

    validates :amount, :resident_id, :type_, :period_start, :presence => true
    validates_numericality_of :amount , :greater_than_equal_to => 0

    validate :period_start_greater_than_period_end
    validate :valid_type
    
    after_save :update_resident_balance
    
    
    TYPE_INITIAL_REWARD = 0
    TYPE_SIGNUP_BONUS = 1
    TYPE_MONTHLY_AWARDS = 2
    TYPE_BUYER = 3
    TYPE_EXPIRED = 4

    def self.types
      {
        TYPE_INITIAL_REWARD => "Initial Balance",
        TYPE_SIGNUP_BONUS => "Sign Up",
        TYPE_MONTHLY_AWARDS => "Monthly Awards",
        TYPE_BUYER => "Buyer",
        TYPE_EXPIRED => "Expired"
      }
    end
    
    def period_start_greater_than_period_end
      if period_start.present? and period_end.present?
        errors[:period_end] << "should be less than period start" if period_start > period_end
      end
    end

    def valid_type
      if !type_.nil? 
        errors[:type_] << "is invalid" if type_.to_i < 0 or type_.to_i > 4
      end
    end

    private
    
      def update_resident_balance
        if type_ != TYPE_EXPIRED
          resident.update_attributes(:balance => resident.total_rewards, :disable_email_validation => true)
        end
        true
      end
    
  end
end
