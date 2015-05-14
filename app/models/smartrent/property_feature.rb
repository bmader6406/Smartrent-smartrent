module Smartrent
  class PropertyFeature < ActiveRecord::Base
    attr_accessible :property_id, :feature_id
    belongs_to :feature
    belongs_to :property
  end
end
