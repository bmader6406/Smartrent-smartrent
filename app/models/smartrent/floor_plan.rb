module Smartrent
  class FloorPlan < ActiveRecord::Base
    belongs_to :property
    
    validates :property_id, :presence => true
    validates_numericality_of :beds, :greater_than_equal_to => 0
    validates_numericality_of :rent_min, :greater_than_equal_to => 0
    validates_numericality_of :rent_max, :greater_than_equal_to => 0
    validates_numericality_of :sq_feet_max, :greater_than_equal_to => 0
    validates_numericality_of :sq_feet_min, :greater_than_equal_to => 0

    def self.import(file)
      f = File.open(file.path, "r:bom|utf-8")
      floor_plans = SmarterCSV.process(f)
      floor_plans.each do |floor_plan|
        property_name = floor_plan[:property_id]
        property = Property.find_by_name(property_name)
        if property
          floor_plan[:property_id] = property.id
          create! floor_plan
        end
      end
    end
  end
end
