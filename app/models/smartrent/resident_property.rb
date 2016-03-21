# this table is maintained by resque
# when the resident change on CRM, resque will update the smartrent residents appropriately

module Smartrent
  class ResidentProperty < ActiveRecord::Base
    belongs_to :property
    belongs_to :resident
    
    validates :property, :resident, :move_in_date, :presence => true
    #validates :move_in_date, :uniqueness => {:scope => [:resident_id, :property_id]}
    
    after_create :create_initial_signup_rewards
    after_create :set_first_move_in
    
    attr_accessor :disable_rewards
    
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
    
      
      def create_initial_signup_rewards
        # monthly reward is created by MonthlyStatusUpdater
        
        # the initial import will create rewards only after the import is done on ResidentCreator
        return true if disable_rewards
        
        return true if !property.eligible?
        
        creation_date = move_in_date.blank? ? created_at : move_in_date
        
        rewards = resident.rewards.all
        
        initial_amount = 0
        months_earned = 0
        
        if move_out_date.blank? || move_out_date && move_out_date > Time.now
          months_earned += (Time.now.difference_in_months(move_in_date) rescue 0)
          
        else
          months_earned += (move_out_date.difference_in_months(move_in_date) rescue 0)
          # count incomplete month for moved out resident
          months_earned += 1
        end
        
        if months_earned >= 1
          initial_amount = Setting.monthly_award*months_earned
          initial_amount = 9900 if initial_amount >= 9900 # 100 will be added by sign up bonus
        end
        
        if !rewards.detect{|r| r.type_ == Reward.TYPE_INITIAL_REWARD }
          Reward.create!({
            :property_id => property.id,
            :resident_id => resident.id,
            :amount => initial_amount,
            :type_ => Reward.TYPE_INITIAL_REWARD,
            :period_start => creation_date,
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
      
      def set_first_move_in
        first_move_in = resident.resident_properties.order("move_in_date asc").limit(1).first.move_in_date
        resident.update_attributes(:first_move_in => first_move_in )
      end
      
  end
end
