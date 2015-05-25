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
    scope :matches_all_features, -> *feature_ids { where(matches_all_features_arel(feature_ids)) }
    scope :where_one_bed, -> *search { where(where_bed_arel(1)) }
    scope :where_two_bed, -> *search { where(where_bed_arel(2)) }
    scope :where_three_more_bed, -> *search { where(where_bed_arel_more_than_eq(3)) }
    scope :where_penthouse, -> *search { where(where_penthouse_arel) }
    before_save do
      self.state = self.state.downcase if self.state
      self.city = self.city.downcase if self.city
      self.county = self.county.downcase if self.county
    end


  def self.ransackable_scopes(auth_object = nil)
    super + %w(matches_all_features) + %w(where_one_bed) + %w(where_two_bed) + %w(where_three_more_bed) + %w(where_penthouse)
  end

  def self.matches_all_features_arel(feature_ids)
    properties = Arel::Table.new(:smartrent_properties)
    features = Arel::Table.new(:smartrent_features)
    property_features = Arel::Table.new(:smartrent_property_features)

    properties[:id].in(
      properties.project(properties[:id])
        .join(property_features).on(properties[:id].eq(property_features[:property_id]))
        .join(features).on(property_features[:feature_id].eq(features[:id]))
        .where(features[:id].in(feature_ids))
        .group(properties[:id])
        .having(features[:id].count.eq(feature_ids.length))
    )
  end

  def self.where_bed_arel(bed_count)
      properties = Arel::Table.new(:smartrent_properties)
      floor_plans = Arel::Table.new(:smartrent_floor_plans)
      properties[:id].in(
        properties.project(properties[:id])
          .join(floor_plans).on(properties[:id].eq(floor_plans[:property_id]))
          .where(floor_plans[:beds].eq(bed_count))
          .group(properties[:id])
      )
  end
  def self.where_bed_arel_more_than_eq(bed_count)
    if search.to_s == "1"
      properties = Arel::Table.new(:smartrent_properties)
      floor_plans = Arel::Table.new(:smartrent_floor_plans)
      properties[:id].in(
        properties.project(properties[:id])
          .join(floor_plans).on(properties[:id].eq(floor_plans[:property_id]))
          .where(floor_plans[:beds].gteq(bed_count))
          .group(properties[:id])
      )
    end
  end
  def self.where_penthouse_arel
      properties = Arel::Table.new(:smartrent_properties)
      floor_plans = Arel::Table.new(:smartrent_floor_plans)
      properties[:id].in(
        properties.project(properties[:id])
          .join(floor_plans).on(properties[:id].eq(floor_plans[:property_id]))
          .where(floor_plans[:penthouse].eq(true))
          .group(properties[:id])
      )
  end


    def self.grouped_by_states(q)
      states = {}
      properties = q.result(distinct: true)#.includes(:features)
      ids = []
      properties.each do |property|
          next if ids.include?(property.id)
          ids.push property.id
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
      states
    end
    def self.ransack(q)
      if q
        q.delete_if {|key, value| key == "penthouse_true" and value == "0"}
        q.delete_if {|key, value| key == "studio_true" and value == "0"}
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
        property_hash[:title] = HTMLEntities.new.decode property_hash[:title]
        property_hash[:description] = HTMLEntities.new.decode property_hash[:description]
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
    def one_bedroom
      floor_plans.where(:beds => 1).order(:rent_min)
    end
    def two_bedrooms
      floor_plans.where(:beds => 2).order(:rent_min)
    end
    def three_bedrooms
      floor_plans.where(:beds => 3).order(:rent_min)
    end
    def four_bedrooms
      floor_plans.where(:beds => 3).order(:rent_min)
    end
    def penthouses
      floor_plans.where(:penthouse => true).order(:rent_min)
    end
  end
end
