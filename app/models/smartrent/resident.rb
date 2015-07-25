module Smartrent
  class Resident < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable, :lockable
    @@sign_up_bonus = nil

    validates_uniqueness_of :origin_id, :allow_nil => true
    validates_presence_of :status, :smartrent_status
    validates_uniqueness_of :email, :allow_blank => true
    validate :valid_smartrent_status

    has_many :resident_properties, :dependent => :destroy
    has_many :properties, :through => :resident_properties
    has_many :resident_homes, :dependent => :destroy
    #has_many :homes, :through => :resident_homes
    has_many :rewards, :dependent => :destroy
    after_create :find_and_set_crm_resident
    scope :active, -> {where(:smartrent_status => self.SMARTRENT_STATUS_ACTIVE)}
    before_validation do
      #Default Status
      self.status = self.class.STATUS_CURRENT if self.status.blank?
    end
    after_commit :flush_rewards_cache
    #has_one :crm_resident, :class_name => "Resident", :foreign_key => :crm_resident_id

    def valid_smartrent_status
      if self.class.smartrent_statuses[smartrent_status].nil?
        errors.add(:smartrent_status, "is invalid")
      end
    end

    def flush_rewards_cache
      Rails.cache.delete([self.class.name, id, "monthly_awards_amount"])
      Rails.cache.delete([self.class.name, id, "total_rewards"])
      Rails.cache.delete([self.class.name, id, "total_months"])
      Rails.cache.delete([self.class.name, id, "champion_amount"])
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
        #resident_hash[:status] = self.STATUS_ACTIVE
        #property = Property.find_by_title(property_name)
        resident_hash[:status] = resident_hash[:smartrent_status]
        resident_hash.delete(:smartrent_status)
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
        property_id = nil
        property_id = property.id if property.present?
        #:status => resident_hash[:smartrent_status], 
        resident_properties_hash = {:property_id => property_id, :move_in_date => nil, :status => ResidentProperty.STATUS_CURRENT}
        begin
          resident_properties_hash[:move_in_date] =  Date.parse(resident_hash[:move_in_date]) if resident_hash[:move_in_date].present?
        rescue Exception => e
          puts "Yo!..there was an exception while parsing date #{resident_hash[:move_in_date]}"
          puts e
        end
        #byebug
        #To cater multiple properties belonging to a resident
        if resident = Resident.find_by_email(resident_hash[:email])
          resident.resident_properties.create(resident_properties_hash) if property.present?
          resident.resident_homes.create!({:home_id => home.id}) if home.present?
        else
          resident = new(resident_hash)
          if resident.save
            #For an imported resident the sign-up bonus be 0
            reward = resident.rewards.where(:type_ => Reward.TYPE_SIGNUP_BONUS).first
            reward.update_attributes(:amount => 0)
            resident.resident_properties.create(resident_properties_hash) if property.present?
            resident.resident_homes.create!({:home_id => home.id}) if home.present?
            puts "Resident has been Saved"
          else
            puts resident.errors.to_a
          end
        end
      end
    end
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

    def status_text
      text = self.class.statuses[self.status]
      if text.nil?
        self.class.STATUS_CURRENT
      else
        text
      end
    end
    def self.statuses
      {self.STATUS_CURRENT => "Current", self.STATUS_NOTICE => "Notice", self.STATUS_PAST => "Past"}
    end
    def self.STATUS_CURRENT
      "Current"
    end
    def self.STATUS_NOTICE
      "Notice"
    end
    def self.STATUS_PAST
      "Past"
    end
    def smartrent_status_text
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
    def cached_monthly_awards_amount
      Rails.cache.fetch([self.class.name, id, "monthly_awards_amount"]) {
        monthly_awards_amount
      }
    end
    def champion_amount
      self.rewards.where(:type_ => Reward.TYPE_CHAMPION).sum(:amount).to_f
    end
    def cached_champion_amount
      Rails.cache.fetch([self.class.name, id, "champion_amount"]) {
        champion_amount
      }
    end
    def total_rewards
      if smartrent_status == self.class.SMARTRENT_STATUS_EXPIRED
        0
      else
        sign_up_bonus + initial_reward + monthly_awards_amount - champion_amount
      end
    end
    def cached_total_rewards
      Rails.cache.fetch([self.class.name, id, "total_rewards"]) {
        total_rewards
      }
    end

    def balance
      total_rewards
    end
    def move_in_date
      #TODO Cache this result
      if resident_properties.present?
        resident_properties.order("move_in_date desc").first.move_in_date
      else
        nil
      end
    end
    def move_out_date
      #TODO Cache this result
      if resident_properties.present?
        resident_properties.order("move_in_date desc").first.move_out_date
      else
        nil
      end
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
    def cached_total_months
      Rails.cache.fetch([self.class.name, id, "total_months"]) {
        total_months
      }
    end

    def update_password(attributes)
      if self.valid_password?(attributes[:current_password])
        attributes.delete(:current_password)
        update_attributes(attributes)
      else
        errors.add(:current_password, "is incorrect")
      end
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
              Rails.cache.delete([self.class.name, property.user_id, "monthly_awards_amount"])
              Rails.cache.delete([self.class.name, property.user_id, "total_rewards"])
            else
              resident.update_attributes(:smartrent_status => self.SMARTRENT_STATUS_INACTIVE)
            end
          end
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
