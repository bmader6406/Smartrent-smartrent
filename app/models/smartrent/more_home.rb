module Smartrent
  class MoreHome < ActiveRecord::Base
    attr_accessible :baths, :beds, :featured, :name, :property_id, :sq_ft
    belongs_to :property
    has_many :floor_plan_images, :dependent => :destroy
    validates_presence_of :baths, :beds, :property_id, :sq_ft
    validates_numericality_of :baths, :beds
    def self.import(file)
      f = File.open(file.path, "r:bom|utf-8")
      homes = SmarterCSV.process(f)
      homes.each do |home_hash|
        property_name = home_hash[:property_id]
        property = Property.find_by_title(property_name)
        if property
          home_hash[:property_id] = property.id
          create! home_hash
        end
      end
    end
  end
end
