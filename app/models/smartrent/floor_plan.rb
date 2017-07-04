module Smartrent
  class FloorPlan < ActiveRecord::Base
    belongs_to :property
    
    validates :property_id, :presence => true
    validates_numericality_of :beds, :greater_than_equal_to => 0
    validates_numericality_of :rent_min, :greater_than_equal_to => 0
    validates_numericality_of :rent_max, :greater_than_equal_to => 0
    validates_numericality_of :sq_feet_max, :greater_than_equal_to => 0
    validates_numericality_of :sq_feet_min, :greater_than_equal_to => 0
    
    before_save :set_studio_penthouse
    before_validation :sanitize_xss

    def sanitize_xss
      self.attributes.each do |key, value|
        self[key] = ActionView::Base.full_sanitizer.sanitize(self[key]) if self[key].is_a? String
        self[key] = self[key].strip if self[key].respond_to?("strip")
      end
    end
    
    private
    
      def set_studio_penthouse
        name_lc = name.to_s.downcase
        
        self.studio = name_lc.include?("studio") || name_lc.include?("s0")
        self.penthouse = name_lc.include?("penthouse")
        
        true
      end
      
  end
end
