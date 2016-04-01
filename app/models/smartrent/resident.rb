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
    has_one :current_property, :class_name => "Property", :primary_key => "current_property_id", :foreign_key => "id"
    
    
    validates :smartrent_status, :presence => true
    validates :email, :uniqueness => true
    validate :valid_smartrent_status
    
    before_save :set_balance
    before_save :set_email_check_and_subscribed
    
    attr_accessor :disable_email_validation

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
    
    def self.SMARTRENT_STATUS_MAXIMUM
      "Maximum"
    end

    def self.SMARTRENT_STATUS_BUYER
      "Buyer"
    end

    def self.SMARTRENT_STATUS_ARCHIVE
      "Archive"
    end

    def self.smartrent_statuses
      {
        self.SMARTRENT_STATUS_ACTIVE => "Active", 
        self.SMARTRENT_STATUS_INACTIVE => "Inactive", 
        self.SMARTRENT_STATUS_EXPIRED => "Expired",
        self.SMARTRENT_STATUS_MAXIMUM => "Maximum",
        self.SMARTRENT_STATUS_BUYER => "Buyer", 
        self.SMARTRENT_STATUS_ARCHIVE => "Archive"
      }
    end

    def self.changable_smartrent_statuses
      {
        self.SMARTRENT_STATUS_BUYER => "Buyer",
        self.SMARTRENT_STATUS_ARCHIVE => "Archive"
      }
    end

    def smartrent_status_text
      smartrent_status
    end
    
    def subscribe_status
      subscribed ? "Yes" : "No"
    end
    
    def full_name
      "#{first_name} #{last_name}".strip
    end
    
    def self.types
      {0 => "First Type"}
    end
    
    def crm_resident      
      # search by email is better than crm_resident_id
      # because the id "link" will be broken when the user do the full upload, result in duplicated sr resident
      # (mysql is not case sensitive but mongodb is)
      @crm_resident ||= begin
        cr = ::Resident::where(:email_lc => email.to_s.downcase).first
        if !cr
          ::Resident::find(crm_resident_id) rescue nil
        end
      end
    end
    
    # preload
    def crm_resident=(r)
      @crm_resident = r
    end
    
    # share crm info
    def name
      crm_resident.full_name rescue "N/A"
    end
    
    def address
      crm_resident.street rescue "N/A"
    end
    
    def city
      crm_resident.city rescue "N/A"
    end
    
    def state
      crm_resident.state rescue "N/A"
    end
    
    def zip
      crm_resident.zip rescue "N/A"
    end

    def update_changable_smartrent_status(smartrent_status)
      smartrent_status = smartrent_status.capitalize
      if self.class.changable_smartrent_statuses.include? smartrent_status
        update_attributes({:smartrent_status => smartrent_status})
      else
        errors.add(:smartrent_status, "is invalid")
        false
      end
    end

    def can_become_buyer_in_property?(property)
      if [self.class.SMARTRENT_STATUS_ACTIVE, self.class.SMARTRENT_STATUS_MAXIMUM].include?(self.smartrent_status)
        resident_property = self.resident_properties.detect{|rp| 
          rp.property_id == property.id && (
            ( rp.move_out_date.blank? && Time.now.difference_in_months(rp.move_in_date) >= 12 ) || 
            ( rp.move_out_date.present? && (rp.move_out_date >= Time.now ? Time.now : rp.move_out_date ).difference_in_months(rp.move_in_date) >= 12 )
          )
        }
        resident_property.present?
      end
    end
    
    def become_buyer(amount)
      amount = amount.to_f
      
      if amount == 0
        errors.add(:amount, "should be greater than 0")
        
      elsif amount > total_rewards
        errors.add(:amount, "should be less than total rewards")
        
      else
        rewards.create!(:amount => amount, :type_ => Reward.TYPE_BUYER, :period_start => Time.now)
        update_attributes!(:smartrent_status => self.class.SMARTRENT_STATUS_BUYER, :buyer_amount => amount)
        
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
      rp = resident_properties.includes(:property).detect{|rp| rp.status == Smartrent::ResidentProperty.STATUS_CURRENT }
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
      end
      monthly_amount
    end

    def buyer_amount
      rewards.where(:type_ => Reward.TYPE_BUYER).sum(:amount).to_f
    end

    def total_rewards
      if smartrent_status == self.class.SMARTRENT_STATUS_EXPIRED
        total = 0
        
      else
        total = sign_up_bonus + initial_reward + monthly_awards_amount
        total = 10000 if total > 10000
        total = total - buyer_amount
      end

      total
    end
    
    def total_months
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
      
      def set_balance
        if smartrent_status_changed? && smartrent_status == self.class.SMARTRENT_STATUS_EXPIRED 
          self.balance = 0
        end
        
        if balance == 10000
          self.smartrent_status = self.class.SMARTRENT_STATUS_MAXIMUM
        end
        
        true
      end
      
      def set_email_check_and_subscribed
        if email.include?("@noemail")
          self.email_check = "Bad"
          self.subscribed = false
        end
        
        true
      end
      
    
    protected
      
      # Some residents have this email format:
      #- Allie.donovan@hotmail.co.uk; alex.donovan@hilton.com
      #- KatCzeck21@hotmail.com, kspedden2005@yahoo.com
      #- Burt0096@UMN,edu
      #- Christian.Motsebo@yahoo,com
      
      def yardi_email_pair?
        return true if disable_email_validation
        
        email = self.email.to_s
        
        if email.include?(";") && email.scan("@").length > 1
          return true
        
        elsif email.include?("/") && email.scan("@").length > 1
          return true
          
        elsif email.include?("and") && email.scan("@").length > 1
          return true
        
        elsif email.include?(":") && email.scan("@").length > 1
          return true
          
        elsif email.include?("---") && email.scan("@").length > 1
          return true
          
        elsif email.include?(",") && email.scan("@").length > 1
          return true
        
        end
        
        return false
      end
      
      # override devise methods to disable validation for yardi email
      def email_required?
        !yardi_email_pair?
      end
      
      def email_changed?
        !yardi_email_pair?
      end
      
      
  end
end
