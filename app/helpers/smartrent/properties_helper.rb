module Smartrent
  module PropertiesHelper
    
    def floor_plan_dict(properties) # reduce n+1 query issue
      dict = {}
      
      FloorPlan.where(:property_id => properties.collect{|p| p.id }).select("property_id, beds, penthouse, rent_min").each do |f|
        if dict[f.property_id]
          dict[f.property_id] << f
        else
          dict[f.property_id] = [f]
        end
      end
      
      dict
    end
    
  end
end
