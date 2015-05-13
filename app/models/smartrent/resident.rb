module Smartrent
  class Resident < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable, :lockable
    # Setup accessible (or protected) attributes for your model
    attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :address, :zip, :state, :move_in_date, :move_out_date, :home_phone, :work_phone, :cell_phone, :company, :house_hold_size, :pets_count, :contract_signing_date, :apartment_id, :type_, :status, :current_community, :city, :state, :country, :current_password, :origin_id, :property_id
    validates_uniqueness_of :origin_id, :allow_nil => true
    validates_presence_of :status, :name

    #attr_accessor :original_password
    # attr_accessible :title, :body
    belongs_to :apartment
    has_many :rewards, :dependent => :destroy

    def self.import(file)
      if file.class == "File"
        f = File.open(file.path, "r:bom|utf-8")
      else
        f = File.open(Rails.root.to_path + "/app/assets/residents.csv")
      end
      residents = SmarterCSV.process(f)
      properties = Property.keyed_by_title
      residents.each do |resident_hash|
        #resident_hash = {:origin_id => 10, :property_id => "asf", :apartment_id => 10, :name => "asdf", :email => "yo@yo.com"}
        generated_password = Devise.friendly_token.first(8)
        resident_hash[:password] = generated_password
        property_name = resident_hash[:property_id]
        resident_hash[:property_id] = nil
        begin
          resident_hash[:move_in_date] = resident_hash[:move_in_date].to_date.to_s if resident_hash[:move_in_date]
        rescue Exception => e
          puts "Yo!..there was an exception while importing residents"
          puts e
        end
        #property = Property.find_by_title(property_name)
        property = nil
        if properties[property_name].present?
          property = properties[property_name]
        end
        resident_hash[:status] = Resident.STATUS_ACTIVE
        resident_hash[:property_id] = property.id if property
        create resident_hash
      end
    end
    def self.statuses
      {self.STATUS_ACTIVE => "Active", self.STATUS_INACTIVE => "Inactive", self.STATUS_EXPIRED => "Expired", self.STATUS_CHAMPION => "Champion", self.STATUS_ARCHIVE => "Archive"}
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
    def self.smartrent_stauses
      {self.SMARTRENT_STATUS_CURRENT => "Current", self.SMARTRENT_STATUS_NOTICE => "Notice", self.SMARTRENT_STATUS_PAST => "Past"}
    end
    def self.SMARTRENT_STATUS_CURRENT
      0
    end
    def self.SMARTRENT_STATUS_NOTICE
      1
    end
    def self.SMARTRENT_STATUS_PAST
      2
    end
    def smartrent_status_text
      self.class.smartrent_stauses[smartrent_status]
    end
    def self.types
      {0 => "First Type"}
    end
    def archive
      update_attributes(:status => self.class.STATUS_ARCHIVE)
    end
    after_create do
      Reward.create!(:resident_id => self.id, :amount => Reward.SIGNUP_BONUS, :type_ => Reward.TYPE_SIGNUP_BONUS, :period_start => Time.now, :period_end => 1.year.from_now)
      if move_in_date.present? and ((Time.now.month - move_in_date.month) >= 1 and (move_out_date.nil? or (move_out_date.month - Time.now.month) == 1))
        Reward.create!(:resident_id => self.id, :amount => Reward.MONTHLY_AWARDS, :type_ => Reward.TYPE_MONTHLY_AWARDS, :period_start => Time.now, :period_end => 1.year.from_now)
      end
      #Reward.create(:resident_id => self.id, :amount => Reward.INITIAL_REWARD, :type => Reward.TYPE_INITIAL_REWARD, :period_start => Time.now, :period_end =>  1.year.from_now)
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
      rewards = self.rewards.where(:type_ => Reward.TYPE_INITIAL_REWARD)
      if rewards.present?
        rewards.first.amount
      else
        0.0
      end
    end
    def monthly_awards_amount
      self.rewards.where(:type_ => Reward.TYPE_MONTHLY_AWARDS).sum(:amount).to_f
    end
    def total_rewards
      sign_up_bonus + initial_reward + monthly_awards_amount
    end
    def total_months
      if self.move_in_date.nil?
        0
      elsif self.move_out_date.nil?
        ((Time.now - self.move_in_date)/(60*60*24)).to_i
      else
        ((self.move_out_date - self.move_in_date)/(60*60*24)).to_i
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
