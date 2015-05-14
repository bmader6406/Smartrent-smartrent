module Smartrent
  class Feature < ActiveRecord::Base
    attr_accessible :name
    has_many :property_features, :dependent => :destroy
    has_many :properties, :through => :apartment_features
    validates_uniqueness_of :name, :allow_blank => false
  end
end
