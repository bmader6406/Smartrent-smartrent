# this table is maintained by resque
# when the resident change on CRM, resque will update the smartrent residents appropriately

module Smartrent
  class ResidentProperty < ActiveRecord::Base
    belongs_to :property
    belongs_to :resident
    
    validates :property, :resident, :move_in_date, :presence => true
    #validates :move_in_date, :uniqueness => {:scope => [:resident_id, :property_id]}
    
    after_create :reset_rewards_table
    # after_create :create_initial_signup_rewards
    after_create :set_first_move_in
    after_destroy :remove_resident_if_does_not_live
    
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

    def reset_rewards_table
      # pp "Resetting rewards table..."
      self.resident
      resident.rewards.destroy_all if resident.rewards.count > 0
      resident.update_attributes(:smartrent_status => Smartrent::Resident::STATUS_ACTIVE)

      # To awards initial balance till 29 Feb 2016
      reward_start_time = DateTime.now.change(:day =>25,:month => 02,:year => 2016)

      #initial_expirty_date is used for expiring initial balance if it exceeds 24 months
      initial_expirty_date = reward_start_time
      rps = resident.resident_properties.where('move_in_date > ? ', reward_start_time)
      initial_expirty_date = rps.min_by{|rp| rp.move_in_date }.move_in_date if rps.count > 0
      if rps.count > 0 and rps.first.property.versions.count > 0
        initial_expirty_date = rps.first.property.versions.last.created_at.advance(:months=>1)
      end

      pp "initial_expirty_date: #{initial_expirty_date}"

      create_initial_signup_rewards(reward_start_time,resident,initial_expirty_date)

      if resident.smartrent_status != Smartrent::Resident::STATUS_EXPIRED and rps.count > 0
        unless resident.rewards.all.collect(&:type_).include?(1)
          Smartrent::Reward.create!({
              :property_id => rps.first.property_id,
              :resident_id => resident.id,
              :amount => Smartrent::Setting.sign_up_bonus,
              :type_ => Reward::TYPE_SIGNUP_BONUS,
              :period_start => initial_expirty_date.beginning_of_month
          })
        end
      end

      time = DateTime.now.change(:day =>1,:month => 03,:year => 2016)
      end_time = Time.now.advance(:months => -1)

      # TODO: recheck this for possibility of running this at 1st of every month at first second
      while time <= end_time do 
          pp "award_time:  #{time}"
          Smartrent::MonthlyStatusUpdater.perform(time,true,nil,resident.id)
          time = time.advance(:months=>1)
      end

      pp "Reset completed..."
      return true
    end

    private

    def create_initial_signup_rewards(time = Time.now,r=resident,time_expiry)
        # monthly reward is created by MonthlyStatusUpdater
        
        # the initial import will create rewards only after the import is done on ResidentCreator
        return true if disable_rewards
        
        # return true if !property.eligible?
        
        if r.rewards.where(:type_ => [Reward::TYPE_INITIAL_REWARD, Reward::TYPE_SIGNUP_BONUS]).count == 0
          # pp "create initial rewards..."
          Smartrent::ResidentCreator.create_initial_signup_rewards(r, time, time_expiry)
        else
          # pp "initial rewards have been created"
        end
      end


      def set_first_move_in
        first_move_in = resident.resident_properties.order("move_in_date asc").limit(1).first.move_in_date
        resident.update_attributes(:first_move_in => first_move_in, :disable_email_validation => true)
      end
      
      def remove_resident_if_does_not_live
        resident.destroy if resident.resident_properties.count == 0
      end

    end
  end
