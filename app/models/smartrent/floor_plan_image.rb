module Smartrent
  class FloorPlanImage < ActiveRecord::Base
    attr_accessible :caption, :home_id, :image
    has_attached_file :image
    validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/
    validates_presence_of :home, :image, :caption
  end
end
