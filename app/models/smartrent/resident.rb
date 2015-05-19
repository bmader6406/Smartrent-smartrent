module Smartrent
  class Resident < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable, :lockable
    # Setup accessible (or protected) attributes for your model
    attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :address, :zip, :state, :move_in_date, :move_out_date, :home_phone, :work_phone, :cell_phone, :company, :house_hold_size, :pets_count, :contract_signing_date, :type_, :status, :current_community, :city, :state, :country, :current_password, :origin_id, :property_id, :home_id, :sign_up_bonus
    #attr_reader :sign_up_bonus
    @@sign_up_bonus = 0

    validates_uniqueness_of :origin_id, :allow_nil => true
    validates_presence_of :status

    #attr_accessor :original_password
    # attr_accessible :title, :body
    belongs_to :property
    belongs_to :home
    has_many :rewards, :dependent => :destroy

    def sign_up_bonus
      sign_up_reward = rewards.where(:type_ => Reward.TYPE_SIGNUP_BONUS)
      if sign_up_reward.present?
        sign_up_reward.first.amount.to_f
      else
        0.0
      end
    end

    def sign_up_bonus=(bonus)
      @@sign_up_bonus = bonus
    end

    def self.import(file)
      if file.class.to_s == "ActionDispatch::Http::UploadedFile"
        f = File.open(file.path, "r:bom|utf-8")
      else
        f = File.open(Rails.root.to_path + "/app/assets/residents.csv")
      end
      residents = SmarterCSV.process(f)
      properties = Property.keyed_by_title
      homes = Home.keyed_by_title
      residents.each do |resident_hash|
        #resident_hash = {:origin_id => 10, :property_id => "asf", :apartment_id => 10, :name => "asdf", :email => "yo@yo.com"}
        generated_password = Devise.friendly_token.first(8)
        resident_hash[:password] = generated_password
        property_name = resident_hash[:property_id]
        home_name = resident_hash[:home_id]
        resident_hash[:property_id] = nil
        resident_hash[:home_id] = nil
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
        if homes[home_name].present?
          home = homes[home_name]
        end
        if resident_hash[:status] == "Y"
          resident_hash[:status] = Resident.STATUS_INACTIVE
        else
          resident_hash[:status] = Resident.STATUS_ACTIVE
        end
        resident_hash[:property_id] = property.id if property
        resident_hash[:home_id] = home.id if home
        create! resident_hash
      end
    end
    def self.statuses
      {self.STATUS_ACTIVE => "Active", self.STATUS_INACTIVE => "Inactive", self.STATUS_EXPIRED => "Expired", self.STATUS_CHAMPION => "Champion", self.STATUS_ARCHIVE => "Archive"}
    end
    def self.STATUS_INACTIVE
      0
    end
    def self.STATUS_ACTIVE
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
      if @@sign_up_bonus.present?
        sign_up_bonus = @@sign_up_bonus
      else
        sign_up_bonus = Setting.sign_up_bonus
      end
      if !rewards.where(:type_ => Reward.TYPE_SIGNUP_BONUS).present?
        Reward.create!(:resident_id => self.id, :amount => sign_up_bonus, :type_ => Reward.TYPE_SIGNUP_BONUS, :period_start => Time.now, :period_end => 1.year.from_now)
      end
      if move_in_date.present? and ((Time.now.month - move_in_date.month) >= 1 and (move_out_date.nil? or (move_out_date.month - Time.now.month) == 1))
        Reward.create!(:resident_id => self.id, :amount => Setting.monthly_award, :type_ => Reward.TYPE_MONTHLY_AWARDS, :period_start => Time.now, :period_end => 1.year.from_now)
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
        (Time.now.year * 12 + Time.now.month) - (self.move_in_date.year * 12 + self.move_in_date.month)
      else
        (self.move_out_date.year * 12 + self.move_out_date.month) - (self.move_in_date.year * 12 + self.move_in_date.month)
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
