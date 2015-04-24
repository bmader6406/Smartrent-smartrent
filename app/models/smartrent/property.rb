module Smartrent
  class Property < ActiveRecord::Base
    attr_accessible :address, :description, :lat, :left_image, :left_image_description, :lng, :title, :website
    has_attached_file :left_image
    validates_attachment_content_type :left_image, :content_type => /\Aimage\/.*\Z/
    validates_presence_of :title, :website, :description, :address
    validates_uniqueness_of :title, :case_sensitive => false

    before_save do
      self.url = self.to_param
    end
    def to_param
      title.parameterize
    end
  end
end
