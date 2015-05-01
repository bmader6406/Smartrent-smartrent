module Smartrent
  class FloorPlanImage < ActiveRecord::Base
    attr_accessible :caption, :home_id, :image
    has_attached_file :image
    validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/
    validates_presence_of :home_id, :image, :caption
    def self.import(file)
      f = File.open(file.path, "r:bom|utf-8")
      floor_plan_images = SmarterCSV.process(f)
      floor_plan_images.each do |floor_plan_image_hash|
        home_name = floor_plan_image_hash[:home_id]
        home = Home.find_by_name(home_name)
        floor_plan_image_hash[:home_id] = home.id
        puts floor_plan_image_hash
        create! floor_plan_image_hash
      end
    end
  end
end
