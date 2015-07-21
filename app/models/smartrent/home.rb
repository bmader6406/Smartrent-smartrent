#encoding: utf-8
module Smartrent
  class Home < ActiveRecord::Base
    #attr_accessible :address, :description, :latitude, :image, :image_description, :longitude, :title, :website, :video_url, :phone_number, :home_page_desc, :city, :state, :search_page_description, :origin_id, :url, :county
    has_attached_file :image, :styles => {:home_page => "195x145>", :search_page => "149x112>"}
    validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/
    validates_presence_of :title
    validates_uniqueness_of :title, :case_sensitive => false
    has_many :resident_homes, :dependent => :destroy
    has_many :residents, :through => :resident_homes
    has_many :more_homes, :dependent => :destroy
    #process_in_background :image
    #geocoded_by :complete_street_address
    #after_validation :geocode

    before_save do
      self.url = self.to_param
    end
    def to_param
      title.parameterize
    end

    def self.import(file)
      if file.class.to_s == "ActionDispatch::Http::UploadedFile"
        f = File.open(file.path, "r:bom|utf-8")
      else
        f = File.open(Smartrent::Engine.root.to_path + "/data/homes.csv")
      end
      homes = SmarterCSV.process(f)
      homes.each do |home_hash|
        home_hash.delete(:wp_post_date)
        create! home_hash
      end
    end
    def self.keyed_by_title
      homes = {}
      all.each do |home|
        homes[home.title] = home
      end
      homes
    end
  end
end
