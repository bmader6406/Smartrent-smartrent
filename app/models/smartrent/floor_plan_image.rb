module Smartrent
  class FloorPlanImage < ActiveRecord::Base
    belongs_to :more_home
    
    validates :more_home_id, :image, :presence => true
    
    has_attached_file :image,
      :storage => :s3,
      :s3_credentials => "#{Rails.root.to_s}/config/s3.yml",
      :path => ":class/:attachment/:id/:style/:filename"
  
    validates_attachment :image,
       :size => {:less_than => 10.megabytes, :message => "file size must be less than 10 megabytes" },
       :content_type => {
         :content_type => ['image/pjpeg', 'image/jpeg', 'image/png', 'image/x-png', 'image/gif'],
         :message => "must be either a JPEG, PNG or GIF image"
        }
    
    scope :visible, -> { where(is_visible:  true) }
    
    def self.import(file)
      if file.class.to_s == "ActionDispatch::Http::UploadedFile"
        f = File.open(file.path, "r:bom|utf-8")
      else
        f = File.open(Smartrent::Engine.root.to_path + "/data/floor_plan_images.csv")
      end
      floor_plan_images = SmarterCSV.process(f)
      floor_plan_images.each do |floor_plan_image_hash|
        home_name = floor_plan_image_hash[:more_home_id]
        more_home = MoreHome.find_by_name(home_name)
        if more_home.present?
          floor_plan_image_hash[:more_home_id] = more_home.id
          create floor_plan_image_hash
        else
          puts "Can't as home is not present"
        end
      end
    end
    
  end
end
