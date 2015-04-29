module Smartrent
  class ApartmentFeature < ActiveRecord::Base
    attr_accessible :apartment_id, :feature_id
    belongs_to :feature
    belongs_to :apartment
  end
end
