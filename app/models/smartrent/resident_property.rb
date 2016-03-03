# this table is maintained by resque
# when the resident change on CRM, resque will update the smartrent residents appropriately

module Smartrent
  class ResidentProperty < ActiveRecord::Base
    belongs_to :property
    belongs_to :resident
    
    validates :property, :resident, :move_in_date, :presence => true
    #validates :move_in_date, :uniqueness => {:scope => [:resident_id, :property_id]}
    
    after_create :create_rewards
    
    def self.STATUS_CURRENT
      "Current"
    end
    
    def self.STATUS_PAST
      "Past"
    end
    
    def self.STATUS_NOTICE
      "Notice"
    end
    
    def self.STATUS_FUTURE
      "Future"
    end
    
    def self.statuses
      {
        self.STATUS_CURRENT => "Current", 
        self.STATUS_PAST => "Past", 
        self.STATUS_NOTICE => "Notice",
        self.STATUS_FUTURE => "Future"
      }
    end
    
    private
    
      def create_rewards
        # create inital, signup rewards
        creation_date = move_in_date.blank? ? created_at : move_in_date
        
        rewards = resident.rewards.all
        
        if move_out_date.blank? || move_out_date && move_out_date > Time.now
          move_in_diff = (Time.now.difference_in_months(move_in_date)) rescue 0
          
        else
          move_in_diff = (move_out_date.difference_in_months(move_in_date)) rescue 0
        end
        
        initial_amount = 0
        months_earned = 0
        
        if property.eligible? && move_in_diff >= 1
          initial_amount = Setting.monthly_award*move_in_diff
          months_earned = move_in_diff
          initial_amount = 10000 if initial_amount > 10000
        end
        
        if !rewards.detect{|r| r.type_ == Reward.TYPE_INITIAL_REWARD }
          Reward.create!({
            :property_id => property.id,
            :resident_id => resident.id,
            :amount => initial_amount,
            :type_ => Reward.TYPE_INITIAL_REWARD,
            :period_start => creation_date,
            :period_end => Time.now.prev_month.end_of_month,
            :months_earned => months_earned
          })
        end
        
        if !rewards.detect{|r| r.type_ == Reward.TYPE_SIGNUP_BONUS }
          Reward.create!({
            :property_id => property.id,
            :resident_id => resident.id,
            :amount => Setting.sign_up_bonus,
            :type_ => Reward.TYPE_SIGNUP_BONUS,
            :period_start => creation_date
          })
        end
        
      end
      
  end
end
