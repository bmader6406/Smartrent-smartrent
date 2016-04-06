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
    
    STATUS_CURRENT = "Current"
    STATUS_PAST = "Past"
    STATUS_NOTICE = "Notice"
    STATUS_FUTURE = "Future"
    
    def self.statuses
      {
        STATUS_CURRENT => "Current", 
        STATUS_PAST => "Past", 
        STATUS_NOTICE => "Notice",
        STATUS_FUTURE => "Future"
      }
    end
    
    private
    
      
      def create_initial_signup_rewards
        # monthly reward is created by MonthlyStatusUpdater
        
        # the initial import will create rewards only after the import is done on ResidentCreator
        return true if disable_rewards
        
        return true if !property.eligible?
        
        if resident.rewards.where(:type_ => [Reward::TYPE_INITIAL_REWARD, Reward::TYPE_SIGNUP_BONUS]).count == 0
          pp "create initial rewards..."
          Smartrent::ResidentCreator.create_initial_signup_rewards(resident, Time.now)
        else
          pp "initial rewards have been created"
        end
      end
      
      def set_first_move_in
        first_move_in = resident.resident_properties.order("move_in_date asc").limit(1).first.move_in_date
        resident.update_attributes(:first_move_in => first_move_in, :disable_email_validation => true)
      end
      
  end
end
