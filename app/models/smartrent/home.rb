#encoding: utf-8
module Smartrent
  class Home < ActiveRecord::Base
    has_many :resident_homes, :dependent => :destroy
    #has_many :residents, :through => :resident_homes
    has_many :more_homes, :dependent => :destroy
    #process_in_background :image
    #geocoded_by :complete_street_address
    #after_validation :geocode
    
    has_attached_file :image,
      :styles => {
        :home_page => "245x210#",
        :search_page => "230x130#",
        :desc_page => "320x200#"
      },
      :storage => :s3,
      :s3_protocol => :https,
      :s3_credentials => "#{Rails.root.to_s}/config/s3.yml",
      :path => ":class/:attachment/:id/:style/:filename"

    validates_attachment :image,
      :size => {:less_than => 10.megabytes, :message => "file size must be less than 10 megabytes" },
      :content_type => {
        :content_type => ['image/pjpeg', 'image/jpeg', 'image/png', 'image/x-png', 'image/gif'],
        :message => "must be either a JPEG, PNG or GIF image"
      }
    
    validates :title, :presence => true, :uniqueness => true
    
    scope :visible, -> { where(is_visible:  true) }
    
    before_create :set_position
    before_save :set_url

    before_validation :sanitize_xss

    def sanitize_xss
      exclude_list = [ "description", "home_page_desc", "search_page_description" ];
      SanitizeXss.sanitize(self,exclude_list)
    end
    
    def to_param
      url || title.parameterize
    end
    
    def visible_more_homes
      @visible_more_homes ||= more_homes.collect{|mh| mh if mh.is_visible? }.compact
    end

    def self.import(file)
      #image,wp_post_date,title,search_page_description,address,city,latitude,longitude,phone_number,image_description,home_page_desc,description,state,video_url,website
      resident_map = {
        :image => 0,
        :title => 2,
        :search_page_description => 3,
        :address => 4,
        :city => 5,
        :latitude => 6,
        :longitude => 7,
        :phone_number => 8,
        :image_description => 9,
        :home_page_desc => 10,
        :description => 11,
        :state => 12,
        :video_url => 13,
        :website => 14
      }
      
      if file.class.to_s == "ActionDispatch::Http::UploadedFile"
        f = File.open(file.path, "r:bom|utf-8")
      else
        f = File.open(Smartrent::Engine.root.to_path + "/data/homes.csv")
      end
      
      index = 0
      
      CSV.foreach(f) do |row|
        index += 1
        next if index == 1
        home_hash = {}
        resident_map.each do |key, index|
          home_hash[key] = row[index]
        end
        Smartrent::Home.create! home_hash
      end
      
      # also import MoreHome and FloorPlanImage if no input file
      if file.class.to_s != "ActionDispatch::Http::UploadedFile"
        MoreHome.import("")
        FloorPlanImage.import("")
      end
    end
    
    private
    
      def set_url
        self.url = self.to_param if !self.url
      end
      
      def set_position
        self.position = self.class.unscoped.maximum(:position).to_i + 1
        true
      end
  end
end
