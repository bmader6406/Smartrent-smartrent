module Smartrent
  class Resident < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable, :lockable
    # Setup accessible (or protected) attributes for your model
    attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :address, :zip, :state, :move_in_date, :move_out_date, :home_phone, :work_phone, :cell_phone, :company, :house_hold_size, :pets_count, :contract_signing_date, :apartment_id, :type_, :status, :current_community, :city, :state, :country, :current_password

    #attr_accessor :original_password
    # attr_accessible :title, :body
    belongs_to :apartment
    def self.statuses
      {0 => "Active", 1 => "Inactive", 2 => "Expired", 3 => "Champion", 4 => "Archive"}
    end
    def self.STATUS_ACTIVE
      0
    end
    def self.STATUS_INACTIVE
      1
    end
    def self.STATUS_EXPIRED
      2
    end
    def self.STATUS_CHAMPION
      3
    end
    def self.STATUS_ARCHIVE
      4
    end
    def status_text
      self.class.statuses[self.status]
    end
    def self.types
      {0 => "First Type"}
    end
    def archive
      update_attributes(:status => self.class.STATUS_ARCHIVE)
    end
    after_create do
      Reward.create(:resident_id => self.id, :amount => Reward.SIGNUP_BONUS, :type => Reward.TYPE_SIGNUP_BONUS, :period_start => Time.now, :period_end => Time.now + 1.year.from_now)
      Reward.create(:resident_id => self.id, :amount => Reward.INITIAL_REWARD, :type => Reward.TYPE_INITIAL_REWARD, :period_start => Time.now, :period_end => Time.now + 1.year.from_now)
    end
    def sign_up_bonus
      reward = Reward.find_by_type_(Reward.TYPE_SIGNUP_BONUS)
      if reward
        reward.amount
      else
        0.0
      end
    end
    def initial_reward
      reward = Reward.find_by_type_(Reward.TYPE_INITIAL_REWARD)
      if reward
        reward.amount
      else
        0.0
      end
    end
    def monthly_awards_amount
      Reward.where(:type_ => Reward.TYPE_MONTHLY_AWARDS).sum(:amount).to_f
    end
    def total_rewards
      sign_up_bonus + initial_reward + monthly_awards_amount
    end
    def total_months
      if !move_in_date
        0
      elsif !move_out_date
        ((Time.now - move_in_date)/(60*60*24)).to_i
      else
        ((move_out_date - move_in_date)/(60*60*24)).to_i
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
  end
end
