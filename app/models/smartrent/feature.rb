module Smartrent
  class Feature < ActiveRecord::Base
    has_many :property_features, :dependent => :destroy
    has_many :properties, :through => :apartment_features
    
    validates :name, :allow_blank => false, :uniqueness => true

    def self.import(file)
      f = File.open(file.path, "r:bom|utf-8")
      features = SmarterCSV.process(f)
      features.each do |feature_hash|
        create feature_hash
      end
    end
    
  end
end
