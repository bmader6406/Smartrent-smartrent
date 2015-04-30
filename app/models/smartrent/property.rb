#encoding: utf-8
module Smartrent
  class Property < ActiveRecord::Base
    attr_accessible :address, :description, :lat, :image, :image_description, :lng, :title, :website, :video_url, :phone_number, :home_page_desc, :city, :state, :search_page_description
    has_attached_file :image, :styles => {:home_page => "195x145>", :search_page => "149x112>"}
    validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/
    validates_presence_of :title, :website, :description, :address, :phone_number, :city, :state
    validates_uniqueness_of :title, :case_sensitive => false
    has_many :homes

    before_save do
      self.url = self.to_param
    end
    def to_param
      title.parameterize
    end
    def self.import(file)
      f = File.open(file.path, "r:bom|utf-8")
      properties = SmarterCSV.process(f)
      properties.each do |property_hash|
        property_hash.delete(:wp_id)
        property_hash.delete(:wp_post_date)
        create! property_hash
      end
    end
  end
end
