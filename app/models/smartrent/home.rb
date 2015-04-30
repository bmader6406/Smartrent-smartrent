module Smartrent
  class Home < ActiveRecord::Base
    attr_accessible :baths, :beds, :featured, :name, :property_id, :sq_ft
    belongs_to :property
    has_many :floor_plan_images
    validates_presence_of :baths, :beds, :property, :sq_ft
  end
end
