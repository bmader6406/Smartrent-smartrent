# this table is maintained by resque
# when the resident change on CRM, resque will update the smartrent residents appropriately

# resident can reset password herself

module Smartrent
  class Resident < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable, :lockable
    
    has_many :resident_properties, :dependent => :destroy
    has_many :properties, :through => :resident_properties
    has_many :resident_homes, :dependent => :destroy
    #has_many :homes, :through => :resident_homes
    has_many :rewards, :dependent => :destroy
    
    
    validates :smartrent_status, :presence => true
    validates :email, :uniqueness => true
    validate :valid_smartrent_status

    after_create :create_reward
    
    def self.SMARTRENT_STATUS_ACTIVE
      "Active"
    end
    def self.SMARTRENT_STATUS_INACTIVE
      "InActive"
    end
    def self.SMARTRENT_STATUS_EXPIRED
      "Expired"
    end
    def self.SMARTRENT_STATUS_CHAMPION
      "Champion"
    end
    def self.SMARTRENT_STATUS_ARCHIVE
      "Archive"
    end
    def self.smartrent_statuses
      {self.SMARTRENT_STATUS_ACTIVE => "Active", self.SMARTRENT_STATUS_INACTIVE => "Inactive", self.SMARTRENT_STATUS_EXPIRED => "Expired", self.SMARTRENT_STATUS_CHAMPION => "Champion", self.SMARTRENT_STATUS_ARCHIVE => "Archive"}
    end

    def smartrent_status_text
      smartrent_status
    end
    
    def self.types
      {0 => "First Type"}
    end
    
    def crm_resident
      @crm_resident ||= ::Resident::where(:id => crm_resident_id).first
    end
    
    def move_in_date
      if resident_properties.present?
        resident_properties.order("move_in_date desc").first.move_in_date
      else
        nil
      end
    end
    
    def move_out_date
      if resident_properties.present?
        resident_properties.order("move_in_date desc").first.move_out_date
      else
        nil
      end
    end
    
    def update_password(attributes)
      if self.valid_password?(attributes[:current_password])
        attributes.delete(:current_password)
        update_attributes(attributes)
      else
        errors.add(:current_password, "is incorrect")
      end
    end
    
    def is_smartrent?
      if properties.present?
      properties.each do |property|
        return true if property.is_smartrent
      end
      else
        false
      end
    end
    
    #### Rewards ####
    
    def sign_up_bonus=(bonus)
      @sign_up_bonus = bonus
    end
    
    def sign_up_bonus
      reward = rewards.find_by_type_(Reward.TYPE_SIGNUP_BONUS)
      if reward
        reward.amount
      else
        0.0
      end
    end
    
    def initial_reward
      rewards = self.rewards.where(:type_ => Reward.TYPE_INITIAL_REWARD)
      if rewards.present?
        rewards.first.amount
      else
        0.0
      end
    end
    
    # TODO: check spreadsheet logic
    def self.move_all_rewards_to_initial_balance(residents)
      residents.each do |resident|
        if resident.rewards.present?
          resident.rewards.where.not(:type_ => Reward.TYPE_INITIAL_REWARD).each do |reward|
            reward.update_attributes(:type_ => Reward.TYPE_INITIAL_REWARD)
          end
        end
      end
    end
    
    def monthly_awards_amount
      if smartrent_status == self.class.SMARTRENT_STATUS_EXPIRED
        monthly_amount = 0
      else
        monthly_amount = self.rewards.where(:type_ => Reward.TYPE_MONTHLY_AWARDS).sum(:amount).to_f
        if (sign_up_bonus + initial_reward + monthly_amount - champion_amount) > 10000
          monthly_amount = monthly_amount - (sign_up_bonus + initial_reward - champion_amount)
          monthly_amount > 0 ? monthly_amount : 0
        end
      end
      monthly_amount
    end

    def champion_amount
      self.rewards.where(:type_ => Reward.TYPE_CHAMPION).sum(:amount).to_f
    end

    def total_rewards
      if smartrent_status == self.class.SMARTRENT_STATUS_EXPIRED
        0
      else
        sign_up_bonus + initial_reward + monthly_awards_amount - champion_amount
      end
    end

    def balance
      total_rewards
    end
    
    def total_months
      months = 0
      move_in_date
      resident_properties.order("move_in_date asc").each_with_index do |resident_property, index|
        #Possible Case: When the move_in_date is present and there are more move_in_dates and move_out_date is nil in each case
        move_in_date = resident_property.move_in_date if move_in_date.nil?
        if resident_property.move_out_date.present?
          months = resident_property.move_out_date.difference_in_months(move_in_date) + months
          move_in_date = nil
        elsif index == resident_properties.count - 1
          #the last element of the array and the move_out_date is still nil
          months = Time.now.difference_in_months(move_in_date) + months
        end
      end
      months
    end

    #The Monthly Cron Job
    def self.monthly_awards_job
      all.each do |resident|
        resident_properties = resident.resident_properties
        if resident.smartrent_status == self.SMARTRENT_STATUS_ACTIVE
          resident_properties = resident_properties.where(:move_out_date => nil)
          if resident_properties.present?
            resident_properties = resident_properties.select{|rp| rp.property.status == Property.STATUS_CURRENT}
            #reisdent_properties = resident_properties.includes(:properties).where{property.status == Property.STATUS_CURRENT}
            resident_properties.each do |resident_property|
              resident = resident_property.resident
              monthly_reward = resident.rewards.where(:type_ => Reward.TYPE_MONTHLY_AWARDS).order("period_start desc").first
              should_add_reward = true
              #Check to ensure if this resident has not been awarded already this month
              if monthly_reward.present? and (monthly_reward.period_start.difference_in_months(Time.now) == 0)
                should_add_reward = false
              end
              if should_add_reward
                resident.rewards.create(:amount => Setting.monthly_award, :type_ => Reward.TYPE_MONTHLY_AWARDS, :period_start => Time.now, :period_end => 1.year.from_now)
              end
            end
          elsif resident_properties.empty?
            resident.update_attributes(:smartrent_status => self.SMARTRENT_STATUS_INACTIVE)
          else
            resident_property = resident_properties.order("move_in_date desc").first
            if Time.now.differnce_in_days(resident_property.move_in_date) > 60
              resident.update_attributes(:smartrent_status => self.SMARTRENT_STATUS_EXPIRED)
            else
              resident.update_attributes(:smartrent_status => self.SMARTRENT_STATUS_INACTIVE)
            end
          end
        end
      end
    end
    
    
    private
      
      def valid_smartrent_status
        if self.class.smartrent_statuses[smartrent_status].nil?
          errors.add(:smartrent_status, "is invalid")
        end
      end
      
      def create_reward
        @sign_up_bonus ||= Setting.sign_up_bonus
        if !rewards.where(:type_ => Reward.TYPE_SIGNUP_BONUS).present?
          rewards.create!(:amount => @sign_up_bonus, :type_ => Reward.TYPE_SIGNUP_BONUS, :period_start => Time.now, :period_end => 1.year.from_now)
        end
      end
  end
end
