module Smartrent
  class PropertyFeature < ActiveRecord::Base
    belongs_to :feature
    belongs_to :property

    validates :feature_id, :uniqueness => {:scope => :property_id}
    
  end
end
