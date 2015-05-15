module Smartrent
  class PropertyFeature < ActiveRecord::Base
    belongs_to :feature
    belongs_to :property
    attr_accessible :property_id, :feature_id
    validates_uniqueness_of :feature_id, scope: :property_id

    def self.import(file)
      f = File.open(file.path, "r:bom|utf-8")
      property_features = SmarterCSV.process(f)
      property_features.each do |property_feature_hash|
        property_title = property_feature_hash[:property_id]
        feature_name = property_feature_hash[:feature_id]
        property = Property.find_by_title(property_title)
        if property
        feature = Feature.find_by_name(feature_name)
          if feature
            create(:property_id => property.id, :feature_id => feature.id)
          end
        end
      end
    end
  end
end