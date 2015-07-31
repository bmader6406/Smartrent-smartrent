module Smartrent
  class Reward < ActiveRecord::Base
    belongs_to :resident
    belongs_to :property
    
    validates :amount, :resident_id, :type_, :period_start, :presence => true
    validates_numericality_of :amount , :greater_than_equal_to => 0
    
    validate :period_start_greater_than_period_end
    validate :valid_type

    def period_start_greater_than_period_end
      if period_start.present? and period_end.present?
        errors[:period_end] << "should be less than period start" if period_start > period_end
      end
    end

    def valid_type
      if !type_.nil? 
        errors[:type_] << "is invalid" if type_.to_i < 0 or type_.to_i > 3
      end
    end
    
    def self.TYPE_INITIAL_REWARD
      0
    end
    def self.TYPE_SIGNUP_BONUS
      1
    end
    def self.TYPE_MONTHLY_AWARDS
      2
    end
    def self.TYPE_CHAMPION
      3
    end

    def self.types
      {
        self.TYPE_INITIAL_REWARD => "Initial Balance",
        self.TYPE_SIGNUP_BONUS => "Sign Up", 
        self.TYPE_MONTHLY_AWARDS => "Monthly Awards", 
        self.TYPE_CHAMPION => "Champion"
      }
    end
    
    def self.import(file)
      f = File.open(file.path, "r:bom|utf-8")
      rewards = SmarterCSV.process(f)
      types = {}
      Reward.types.each do |value, type|
        types[type.downcase] = value
      end
      rewards.each do |reward_hash|
        email = reward_hash[:email]
        resident = Resident.find_by_email(email)
        reward_hash.delete(:email)
        if resident
          if !reward_hash[:period_start].present?
            reward_hash[:period_start] = Time.now
          end
          if reward_hash[:type] and types[reward_hash[:type].downcase].present?
            reward_hash[:type_] = types[reward_hash[:type].downcase]
          end
          reward_hash.delete(:type)
          reward_hash[:resident_id] = resident.id
          create! reward_hash
        end
      end
    end
    
  end
end
