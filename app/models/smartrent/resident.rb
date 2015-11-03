# this table is maintained by resque
# when the resident change on CRM, resque will update the smartrent residents appropriately

# resident can reset password herself

module Smartrent
  class Resident < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable, :lockable, :confirmable
    
    has_many :resident_properties, :dependent => :destroy
    has_many :properties, :through => :resident_properties
    has_many :resident_homes, :dependent => :destroy
    #has_many :homes, :through => :resident_homes
    has_many :rewards, :dependent => :destroy
    
    
    validates :smartrent_status, :presence => true
    validates :email, :uniqueness => true
    validate :valid_smartrent_status

    ## !!! stop devise confirmation. Don't remove this method
    def send_on_create_confirmation_instructions
    end
    
    def self.SMARTRENT_STATUS_ACTIVE
      "Active"
    end

    def self.SMARTRENT_STATUS_INACTIVE
      "Inactive"
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
      {
        self.SMARTRENT_STATUS_ACTIVE => "Active", 
        self.SMARTRENT_STATUS_INACTIVE => "Inactive", 
        self.SMARTRENT_STATUS_EXPIRED => "Expired", 
        self.SMARTRENT_STATUS_CHAMPION => "Champion", 
        self.SMARTRENT_STATUS_ARCHIVE => "Archive"
      }
    end

    def self.changable_smartrent_statuses
      {
        self.SMARTRENT_STATUS_CHAMPION => "Champion",
        self.SMARTRENT_STATUS_ARCHIVE => "Archive"
      }
    end

    def smartrent_status_text
      smartrent_status
    end
    
    def self.types
      {0 => "First Type"}
    end
    
    def crm_resident
      #@crm_resident ||= ::Resident::where(:_id => crm_resident_id).first
      
      # search by email is better than crm_resident_id
      # because the id "link" will be broken when the user do the full upload, result in duplicated sr resident
      # (mysql is not case sensitive but mongodb is)
      @crm_resident ||= ::Resident::where(:email_lc => email.to_s.downcase).first
    end
    
    # preload
    def crm_resident=(r)
      @crm_resident = r
    end
    
    def move_in_date
      resident_properties.order("move_in_date desc").first.move_in_date
    end
    
    def move_out_date
      resident_properties.order("move_in_date desc").first.move_out_date
    end
    
    # share crm info
    def name
      crm_resident.full_name
    end
    
    def address
      crm_resident.street
    end
    
    def city
      crm_resident.city
    end
    
    def state
      crm_resident.state
    end
    
    def zip
      crm_resident.zip
    end

    def update_changable_smartrent_status(smartrent_status)
      smartrent_status = smartrent_status.capitalize
      if self.class.changable_smartrent_statuses.include? smartrent_status
        update_attributes({:smartrent_status => smartrent_status.capitalize})
      else
        errors.add(:smartrent_status, "is invalid")
        false
      end
    end

    def can_become_champion_in_property?(property)
      if self.smartrent_status == self.class.SMARTRENT_STATUS_ACTIVE
        #resident_property = self.resident_properties.detect{|rp| rp.property_id == property.id && Time.now.difference_in_months(rp.move_in_date) >= 12}
        resident_property = self.resident_properties.detect{|rp| rp.property_id == property.id && ((rp.move_out_date.nil? && Time.now.difference_in_months(rp.move_in_date) >= 12) || (rp.move_out_date.present? && rp.move_out_date.difference_in_months(rp.move_in_date) >= 12))}
        resident_property.present?
      end
    end

    def become_champion(amount)
      amount = amount.to_f
      if amount == 0
        errors.add(:amount, "should be greater than 0")
      elsif amount > total_rewards
        errors.add(:amount, "should be less than total rewards")
      else
        rewards.create!(:amount => amount, :type_ => Reward.TYPE_CHAMPION, :period_start => Time.now)
        update_attributes!(:smartrent_status => self.class.SMARTRENT_STATUS_CHAMPION, :champion_amount => amount)
        return true
      end
      return false
    end
    
    # don't define "def email"
    
    ###
    
    def update_password(attributes)
      if self.valid_password?(attributes[:current_password])
        attributes.delete(:current_password)
        update_attributes(attributes)
      else
        errors.add(:current_password, "is incorrect")
      end
    end
    
    def is_smartrent?
      properties.any?{|p| p.is_smartrent? }
    end
    
    def current_community
      rp = resident_properties.includes(:property).detect{|p| p.status == "Current" }
      if rp && rp.property
        rp.property.name
      else
        "N/A"
      end
    end
    
    #### Rewards ####
    
    def sign_up_bonus
      rewards.find_by_type_(Reward.TYPE_SIGNUP_BONUS).amount rescue 0.0
    end
    
    def initial_reward
      rewards.where(:type_ => Reward.TYPE_INITIAL_REWARD).first.amount rescue 0.0
    end
    
    def monthly_awards_amount
      if smartrent_status == self.class.SMARTRENT_STATUS_EXPIRED
        monthly_amount = 0
      else
        monthly_amount = self.rewards.where(:type_ => Reward.TYPE_MONTHLY_AWARDS).sum(:amount).to_f
        # if (sign_up_bonus + initial_reward + monthly_amount - champion_amount) > 10000
        #   monthly_amount = monthly_amount - (sign_up_bonus + initial_reward - champion_amount)
        #   monthly_amount > 0 ? monthly_amount : 0
        # end
      end
      monthly_amount
    end

    def champion_amount
      rewards.where(:type_ => Reward.TYPE_CHAMPION).sum(:amount).to_f
    end

    def total_rewards
      if smartrent_status == self.class.SMARTRENT_STATUS_EXPIRED
        total = 0
      else
        total = sign_up_bonus + initial_reward + monthly_awards_amount - champion_amount
        total = 10000 if total > 10000
      end

      total
    end

    def balance
      total_rewards
    end
    
    def total_months
      # months = 0
      # move_in_date
      # resident_properties.order("move_in_date asc").each_with_index do |resident_property, index|
      #   #Possible Case: When the move_in_date is present and there are more move_in_dates and move_out_date is nil in each case
      #   move_in_date = resident_property.move_in_date if move_in_date.nil?
      #   if resident_property.move_out_date.present?
      #     months = resident_property.move_out_date.difference_in_months(move_in_date) + months
      #     move_in_date = nil
      #   elsif index == resident_properties.count - 1
      #     #the last element of the array and the move_out_date is still nil
      #     months = Time.now.difference_in_months(move_in_date) + months
      #   end
      # end
      # months
      total_months = rewards.find_by_type_(Reward.TYPE_INITIAL_REWARD).months_earned rescue 0
      total_months += rewards.where(:type_ => Reward.TYPE_MONTHLY_AWARDS).count
    end


    #Devise Methods
    def only_if_unconfirmed
      pending_any_confirmation {yield}
    end
  # new function to set the password without knowing the current password used in our confirmation controller. 
    def attempt_set_password(params)
      p = {}
      p[:password] = params[:password]
      p[:password_confirmation] = params[:password_confirmation]
      update_attributes(p)
    end
    def password_match?
        self.password == self.password_confirmation
    end

    private
      
      def valid_smartrent_status
        if self.class.smartrent_statuses[smartrent_status].nil?
          errors.add(:smartrent_status, "is invalid")
        end
      end
  end
end
