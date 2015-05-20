module Smartrent
  class Property < ActiveRecord::Base
    has_many :property_features, :dependent => :destroy
    has_many :features, :through => :property_features
    has_many :residents
    has_many :floor_plans, :dependent => :destroy
    attr_accessible :address, :city, :county, :website, :latitude, :longitude, :phone_number, :short_description, :special_promotion, :state, :studio_price, :title,  :studio, :image, :feature_ids, :origin_id, :bozzuto_url, :email, :promotion_title, :promotion_subtitle, :promotion_url, :promotion_expiration_date, :zip, :description
    has_attached_file :image, :styles => {:search_page => "150x150>"}
    validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/
    validates_presence_of :title
    validates_uniqueness_of :title, :case_sensitive => true
    before_save do
      self.state = self.state.downcase if self.state
      self.city = self.city.downcase if self.city
      self.county = self.county.downcase if self.county
    end
    def self.grouped_by_states(q)
      states = {}
      properties = q.result.uniq#.includes(:features)
      properties.each do |property|
          states[property.state] = {} if states[property.state].nil?
          states[property.state]["cities"] = {}  if states[property.state]["cities"].nil?
          states[property.state]["cities"][property.city] = 0 if states[property.state]["cities"][property.city].nil?
          states[property.state]["cities"][property.city] +=1
          states[property.state]["counties"] = {}  if states[property.state]["counties"].nil?
          states[property.state]["counties"][property.county] = 0 if states[property.state]["counties"][property.county].nil?
          states[property.state]["counties"][property.county] +=1
          states[property.state]["properties"] = []  if states[property.state]["properties"].nil?
          states[property.state]["properties"].push property
          states[property.state]["total"] = 0  if states[property.state]["total"].nil?
          states[property.state]["total"] +=1
      end
      puts states
      states
    end
    def self.ransack(q)
      if q
        q.delete_if {|key, value| key == "one_bedroom_true" and value == "0"}
        q.delete_if {|key, value| key == "two_bedroom_true" and value == "0"}
        q.delete_if {|key, value| key == "three_bedroom_true" and value == "0"}
        q.delete_if {|key, value| key == "four_bedroom_true" and value == "0"}
        q.delete_if {|key, value| key == "penthouse_true" and value == "0"}
        q.delete_if {|key, value| key == "studio_true" and value == "0"}
        q.delete_if {|key, value| key == "one_bedroom_price_or_two_bedroom_price_or_three_bedroom_price_or_four_bedroom_price_or_studio_price_or_pent_house_price_gteq" and value == "0"}
        q.delete_if {|key, value| key == "one_bedroom_price_or_two_bedroom_price_or_three_bedroom_price_or_four_bedroom_price_or_studio_price_or_pent_house_price_lteq" and value == "0"}
      end
      super q
    end
    def self.prices(chose_text)
      prices = []
      (0..10000).step(250).each do |price|
        if price == 0
          price_array = [chose_text, price]
        else
          price_array = ['$' + price.to_s, price]
        end
        prices.push price_array
      end
      prices
    end
    def self.keyed_by_title
      properties = {}
      all.each do |property|
        properties[property.title] = property
      end
      properties
    end
    def self.import(file)
      if file.class.to_s == "ActionDispatch::Http::UploadedFile"
        f = File.open(file.path, "r:bom|utf-8")
      else
        f = File.open(Rails.root.to_path + "/app/assets/properties.csv")
      end
      properties = SmarterCSV.process(f)
      properties.each do |property_hash|
        create property_hash
      end
    end
    def self.statuses
      {self.STATUS_ACTIVE => "Active", self.STATUS_INACTIVE => "Inactive"}
    end
    def self.STATUS_INACTIVE
      0
    end
    def self.STATUS_ACTIVE
      1
    end
    def status_text
      self.class.statuses[self.status]
    end
  end
end
