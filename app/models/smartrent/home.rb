module Smartrent
  class Home < ActiveRecord::Base
    attr_accessible :baths, :beds, :featured, :name, :property_id, :sq_ft
    belongs_to :property
    has_many :floor_plan_images, :dependent => :destroy
    validates_presence_of :baths, :beds, :property, :sq_ft
    def self.import(file)
      f = File.open(file.path, "r:bom|utf-8")
      homes = SmarterCSV.process(f)
      homes.each do |home_hash|
        property_name = home_hash[:property_id]
        property = Property.find_by_title(property_name)
        home_hash[:property_id] = property.id
        create! home_hash
      end
    end
  end
end
