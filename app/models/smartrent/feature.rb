module Smartrent
  class Feature < ActiveRecord::Base
    attr_accessible :name
    has_many :apartment_features, :dependent => :destroy
    has_many :apartments, :through => :apartment_features
  end
end
