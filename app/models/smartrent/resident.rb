module Smartrent
  class Resident < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable, :lockable
    # Setup accessible (or protected) attributes for your model
    #attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :address, :zip, :state, :move_in_date, :move_out_date, :home_phone, :work_phone, :cell_phone, :company, :house_hold_size, :pets_count, :contract_signing_date, :type_, :status, :current_community, :city, :state, :country, :current_password, :origin_id, :property_id, :home_id, :sign_up_bonus
    #attr_reader :sign_up_bonus
    @@sign_up_bonus = nil

    validates_uniqueness_of :origin_id, :allow_nil => true
    validates_presence_of :status
    validates_uniqueness_of :email, :allow_blank => true

    #attr_accessor :original_password
    # #attr_accessible :title, :body
    #belongs_to :property
    has_many :resident_properties, :dependent => :destroy
    has_many :properties, :through => :resident_properties
    has_many :resident_homes, :dependent => :destroy
    has_many :homes, :through => :resident_homes
    has_many :rewards, :dependent => :destroy
    after_create :find_and_set_crm_resident
    #has_one :crm_resident, :class_name => "Resident", :foreign_key => :crm_resident_id
    #
    def self.STATUS_ACTIVE
      "Active"
    end
    def self.STATUS_INACTIVE
      "InActive"
    end
    def self.STATUS_EXPIRED
      "Expired"
    end
    def self.STATUS_CHAMPION
      "Champion"
    end
    def self.STATUS_ARCHIVE
      "Archive"
    end

    def sign_up_bonus
      sign_up_reward = rewards.where(:type_ => Reward.TYPE_SIGNUP_BONUS)
      if sign_up_reward.present?
        sign_up_reward.first.amount.to_f
      else
        0.0
      end
    end

    def crm_resident
      ::Resident::where(:smartrent_resident_id => id)
    end

    def find_and_set_crm_resident
      resident = ::Resident.where(:email => self.email).first
      update_columns(:crm_resident_id => resident.id) if resident
    end

    #Some problem with the above method, always returning 0
    def sign_up_bonus_
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
        f = File.open(Smartrent::Engine.root.to_path + "/data/residents.csv")
      end
      residents = SmarterCSV.process(f)
      properties = Smartrent::Property.keyed_by_name
      units = ::Unit.keyed_by_code
      homes = Home.keyed_by_title
      residents.each do |resident_hash|
        #resident_hash = {:origin_id => 10, :property_id => "asf", :apartment_id => 10, :name => "asdf", :email => "yo@yo.com"}
        generated_password = Devise.friendly_token.first(8)
        resident_hash[:password] = generated_password
        property_name = resident_hash[:property_id]
        unit_code = resident_hash[:unit_id]
        home_name = resident_hash[:home_id]
        resident_hash.delete(:property_id)
        resident_hash.delete(:home_id)
        resident_hash[:property_ids] = []
        resident_hash[:home_ids] = []
        #Setting status as active for the first time
        resident_hash[:status] = self.STATUS_ACTIVE
        #property = Property.find_by_title(property_name)
        property = nil
        unit = nil
        home = nil
        if properties[property_name].present?
          property = properties[property_name]
        end
        if homes[home_name].present?
          home = homes[home_name]
        end
        if units[unit_code].present?
          unit = units[unit_code]
          resident_hash[:unit_id] = unit.id
        else
          resident_hash[:unit_id] = unit_code
        end
        resident_properties_hash = {:status => resident_hash[:smartrent_status], :property_id => property.id, :move_in_date => nil} if property.present?
        resident_hash.delete(:smartrent_status)
        begin
          resident_properties_hash[:move_in_date] =  Date.parse(resident_hash[:move_in_date]) if resident_hash[:move_in_date].present?
        rescue Exception => e
          puts "Yo!..there was an exception while parsing date #{resident_hash[:move_in_date]}"
          puts e
        end
        #byebug
        #To cater multiple properties belonging to a resident
        if resident = Resident.find_by_email(resident_hash[:email])
          resident.resident_properties.create!(resident_properties_hash) if property.present?
          resident.resident_homes.create!({:home_id => home.id}) if home.present?
        else
          resident = new(resident_hash)
          if resident.save
            resident.resident_properties.create!(resident_properties_hash) if property.present?
            resident.resident_homes.create!({:home_id => home.id}) if home.present?
            puts "Resident has been saved"
          else
            puts resident.errors.to_a
          end
        end
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
    def self.smartrent_statuses
      {self.SMARTRENT_STATUS_CURRENT => "Current", self.SMARTRENT_STATUS_NOTICE => "Notice", self.SMARTRENT_STATUS_PAST => "Past"}
    end
    def self.SMARTRENT_STATUS_CURRENT
      "Current"
    end
    def self.SMARTRENT_STATUS_NOTICE
      "Notice"
    end
    def self.SMARTRENT_STATUS_PAST
      "Past"
    end
    def smartrent_status_text
      smartrent_status = "None"
      if resident_properties.present?
        resident_properties.each do |resident_property|
          if resident_property.move_out_date.nil?
            smartrent_status = resident_property.status
          elsif smartrent_status != self.class.SMARTRENT_STATUS_CURRENT and resident_property.status.present?
            smartrent_status = resident_property.status
          end
        end
      end
      smartrent_status
    end
    def self.types
      {0 => "First Type"}
    end
    def archive
      update_attributes(:status => self.class.STATUS_ARCHIVE)
    end
    after_create do
      @@sign_up_bonus ||= Setting.sign_up_bonus
      if !rewards.where(:type_ => Reward.TYPE_SIGNUP_BONUS).present?
        rewards.create!(:amount => @@sign_up_bonus, :type_ => Reward.TYPE_SIGNUP_BONUS, :period_start => Time.now, :period_end => 1.year.from_now)
      end
      #if move_in_date.present? and !property.nil? and property.status == Property.STATUS_CURRENT and ((Time.now.month - move_in_date.month) >= 1 and (move_out_date.nil? or (move_out_date.month - Time.now.month) == 1))
        #rewards.create!(:amount => Setting.monthly_award, :type_ => Reward.TYPE_MONTHLY_AWARDS, :period_start => Time.now, :period_end => 1.year.from_now)
      #end
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
      self.rewards.where(:type_ => Reward.TYPE_MONTHLY_AWARDS).sum(:amount).to_f
    end
    def total_rewards
      sign_up_bonus + initial_reward + monthly_awards_amount
    end

    def balance
      total_rewards
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
    def self.monthly_awards_job
      residents = Resident.where(:status => Resident.STATUS_ACTIVE)
      residents = residents.where("move_out_date is null and property_id is not null") if residents.present?
      residents = residents.includes(:property).where{property.status == Property.STATUS_CURRENT}
      residents.each do |resident|
        monthly_reward = resident.rewards.where(:type_ => Reward.TYPE_MONTHLY_AWARDS).last
        should_add_reward = true
        if monthly_reward.present?
          if (monthly_reward.period_start.year * 12 + monthly_reward.period_start.month) - (Time.now.year * 12 + Time.now.month) == 0
            should_add_reward = false
          end
        end
        if should_add_reward
          resident.rewards.create(:amount => Setting.monthly_award, :type_ => Reward.TYPE_MONTHLY_AWARDS, :period_start => Time.now, :period_end => 1.year.from_now)
        end
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
  end
end
