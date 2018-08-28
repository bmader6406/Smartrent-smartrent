# this table is maintained by resque
# when the resident change on CRM, resque will update the smartrent residents appropriately

module Smartrent
  class ResidentProperty < ActiveRecord::Base
    belongs_to :property
    belongs_to :resident
    
    validates :property, :resident, :move_in_date, :presence => true
    #validates :move_in_date, :uniqueness => {:scope => [:resident_id, :property_id]}
    
    # after_create :reset_rewards_table
    after_save :create_initial_signup_rewards
    after_save :recalculate_rewards_table
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
      #resident.rewards.destroy_all if resident.rewards.count > 0
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
          Smartrent::MonthlyAwardUpdater.perform(time,true,nil,resident.id)
          time = time.advance(:months=>1)
      end

      pp "Reset completed..."
      return true
    end

    def recalculate_rewards_table
      if self.move_in_date_changed? || self.move_out_date_changed? || self.status_changed?
        time = Date.today
        RewardCalculator.perform(time, [self.resident])
      end
    end

    def create_initial_signup_rewards
      if self.property.is_smartrent and self.move_in_date == Date.today
        if self.resident.rewards.where(:type_ => Reward::TYPE_SIGNUP_BONUS).count == 0
         Smartrent::Reward.create!({
          :property_id => self.property_id,
          :resident_id => self.resident.id,
          :amount => Smartrent::Setting.sign_up_bonus,
          :type_ => Reward::TYPE_SIGNUP_BONUS,
          :period_start => self.move_in_date.beginning_of_month
        })
        end
      end
    end

    def eligible_sign_up_date
      rp = self
      move_in = rp.move_in_date
      property = rp.property
      move_out_date = rp.move_out_date ? rp.move_out_date : Date.today
      months = (move_in..move_out_date).map{ |m| m.strftime('%Y%m') }.uniq
      month = eligible_smartrent_months(months).first
      modified_month = month + "01"
      date = DateTime.parse(modified_month).beginning_of_month
    end

    def is_not_expired?
      flag = false
      move_out_date = self.move_out_date
      if move_out_date
        property = self.property
        # need to cross check 
        #.where('created_at > ?', move_out_date)
        property_versions = property.versions
        if property_versions.present?
          property_versions.each do |version|
            if version.reify && version.reify.is_smartrent == true
              if move_out_date + 2.years > version.created_at
                flag = true
                break
              end
            else
              flag = property.is_smartrent
            end
          end
        else
          flag = property.is_smartrent
        end
      else
        flag = true
      end
      flag
    end

    def eligible_smartrent_months(months)
      eligible_smartrent_months = []
      months.each do |month|
        if eligible_month?(month)
          eligible_smartrent_months << month
        end
      end
      eligible_smartrent_months
    end

    private

      def eligible_month?(month)
        property = self.property
        modified_month = month + "01"
        parsed_month = DateTime.parse(modified_month).beginning_of_month
        if property.versions.count > 0
          version = property.versions.where('created_at > ?', parsed_month).first
          if version && version.reify
            if parsed_month.month == version.created_at.month && parsed_month.year == version.created_at.year && !version.reify.is_smartrent
              true
            else
              version.reify.is_smartrent
            end
          else
            property.is_smartrent && parsed_month <= DateTime.now
          end
        else
          if parsed_month <= DateTime.now
            property.is_smartrent
          else
            false
          end
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
