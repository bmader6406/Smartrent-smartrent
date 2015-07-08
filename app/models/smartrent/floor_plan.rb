module Smartrent
  class FloorPlan < ActiveRecord::Base
    #attr_accessible :baths, :beds, :name, :origin_id, :penthouse, :property_id, :rent_max, :rent_min, :sq_feet_max, :sq_feet_min, :url
    validates_numericality_of :beds, :greater_than_equal_to => 0
    validates_numericality_of :rent_min, :greater_than_equal_to => 0
    validates_numericality_of :rent_max, :greater_than_equal_to => 0
    validates_numericality_of :sq_feet_max, :greater_than_equal_to => 0
    validates_numericality_of :sq_feet_min, :greater_than_equal_to => 0
    validates_presence_of :property_id
    #validates_uniqueness_of :name, :case_sensitive => true, :scope => :property_id
    belongs_to :property

    def self.import(file)
      f = File.open(file.path, "r:bom|utf-8")
      floor_plans = SmarterCSV.process(f)
      floor_plans.each do |floor_plan|
        property_title = floor_plan[:property_id]
        property = Property.find_by_title(property_title)
        if property
          floor_plan[:property_id] = property.id
          create! floor_plan
        end
      end
    end
  end
end
