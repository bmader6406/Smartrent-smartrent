#encoding: utf-8
module Smartrent
  class Property < ActiveRecord::Base
    attr_accessible :address, :description, :latitude, :image, :image_description, :longitude, :title, :website, :video_url, :phone_number, :home_page_desc, :city, :state, :search_page_description, :origin_id,:elan_property_number, :lead_to_lease, :yardi_property_id, :l2l_integration_email, :bozzuto_property_no, :date_opened, :date_closed, :street_address, :zip_code, :neighborhood, :metro_region, :owner_group, :apartments_count, :website_host_agency, :monday_open_time, :monday_close_time, :tuesday_open_time, :tuesday_close_time, :wednesday_open_time, :wednesday_close_time, :thursday_open_time, :thursday_close_time, :friday_open_time, :friday_close_time, :saturday_open_time, :saturday_close_time, :sunday_open_time, :sunday_close_time, :invoice_email, :property_email, :property_website_floor_plans_url, :property_website_features_url, :property_website_amenities_url, :property_website_neighborhood_url, :property_website_photo_gallery_url, :property_website_contact_us_url, :scheduling_tool_url, :facebook_url, :google_plus_url, :pinterest_url, :twitter_url, :blog_url, :apartment_ratings_url, :yelp_url, :foursquare_url, :svp_name, :co_ordinator_name, :marketing_manager, :pop_card_id, :instagram_url, :regional_manager, :email_blast_phone_number, :status, :property_status, :tournado_switched_on, :synonym_name, :sort_name, :created_at, :url, :county
    has_attached_file :image, :styles => {:home_page => "195x145>", :search_page => "149x112>"}
    validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/
    validates_presence_of :title
    validates_uniqueness_of :title, :case_sensitive => false
    has_many :homes, :dependent => :destroy
    #geocoded_by :complete_street_address
    #after_validation :geocode

    before_save do
      self.url = self.to_param
    end
    def to_param
      title.parameterize
    end

    def complete_street_address
      self.street_address.to_s + ", " + self.city.to_s + ", " + self.state.to_s + ", USA"
    end
    def self.import(file)
      f = File.open(file.path, "r:bom|utf-8")
      properties = SmarterCSV.process(f)
      properties.each do |property_hash|
        property_hash.delete(:wp_post_date)
        create! property_hash
      end
    end
    def self.keyed_by_title
      properties = {}
      all.each do |property|
        properties[property.title] = property
      end
      properties
    end
  end
end
