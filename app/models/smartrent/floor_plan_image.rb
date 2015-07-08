module Smartrent
  class FloorPlanImage < ActiveRecord::Base
    #attr_accessible :caption, :more_home_id, :image
    has_attached_file :image
    validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/
    validates_presence_of :more_home_id, :image, :caption
    belongs_to :more_home
    def self.import(file)
      f = File.open(file.path, "r:bom|utf-8")
      floor_plan_images = SmarterCSV.process(f)
      floor_plan_images.each do |floor_plan_image_hash|
        home_name = floor_plan_image_hash[:more_home_id]
        more_home = MoreHome.find_by_name(home_name)
        floor_plan_image_hash[:more_home_id] = more_home.id
        create floor_plan_image_hash
      end
    end
  end
end
