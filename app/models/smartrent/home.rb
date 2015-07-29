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
        :home_page => "195x145>",
        :search_page => "149x112>"
      },
      :storage => :s3,
      :processors => [:cropper],
      :s3_credentials => "#{Rails.root.to_s}/config/s3.yml",
      :path => ":class/:attachment/:id/:style/:filename"

    validates_attachment :image,
      :size => {:less_than => 10.megabytes, :message => "file size must be less than 10 megabytes" },
      :content_type => {
        :content_type => ['image/pjpeg', 'image/jpeg', 'image/png', 'image/x-png', 'image/gif'],
        :message => "must be either a JPEG, PNG or GIF image"
      }
    
    validates :title, :presence => true, :uniqueness => true
    
    
    before_save :set_url
    
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
    
    private
    
      def set_url
        self.url = self.to_param
      end
  end
end
