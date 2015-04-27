module Smartrent
  class Property < ActiveRecord::Base
    attr_accessible :address, :description, :lat, :left_image, :left_image_description, :lng, :title, :website, :video_url, :phone_number, :home_page_desc, :search_page_sub_title, :city, :state
    has_attached_file :left_image, :styles => {:home_page => "195x145>", :search_page => "149x112>"}
    validates_attachment_content_type :left_image, :content_type => /\Aimage\/.*\Z/
    validates_presence_of :title, :website, :description, :address, :video_url, :phone_number, :city, :state
    validates_uniqueness_of :title, :case_sensitive => false

    before_save do
      self.url = self.to_param
    end
    def to_param
      title.parameterize
    end
  end
end
