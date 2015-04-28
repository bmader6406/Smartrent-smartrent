module Smartrent
  class ApartmentFeatures < ActiveRecord::Base
    attr_accessible :apartment_id, :feature_id
  end
end
