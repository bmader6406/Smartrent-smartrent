module Smartrent
  class Feature < ActiveRecord::Base
    #attr_accessible :name
    has_many :property_features, :dependent => :destroy
    has_many :properties, :through => :apartment_features
    validates_uniqueness_of :name, :allow_blank => false, :case_sensitive => true

    def self.import(file)
      f = File.open(file.path, "r:bom|utf-8")
      features = SmarterCSV.process(f)
      features.each do |feature_hash|
        create feature_hash
      end
    end
  end
end
