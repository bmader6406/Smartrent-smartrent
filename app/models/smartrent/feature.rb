module Smartrent
  class Feature < ActiveRecord::Base
    has_many :property_features, :dependent => :destroy
    has_many :properties, :through => :apartment_features
    
    validates :name, :allow_blank => false, :uniqueness => true
    before_validation :sanitize_xss

    def sanitize_xss
      self.attributes.each do |key, value|
        self[key] = ActionView::Base.full_sanitizer.sanitize(self[key]) if self[key].is_a? String
        self[key] = self[key].strip if self[key].respond_to?("strip")
      end
    end

    def self.import(file)
      f = File.open(file.path, "r:bom|utf-8")
      features = SmarterCSV.process(f)
      features.each do |feature_hash|
        create feature_hash
      end
    end
    
  end
end
