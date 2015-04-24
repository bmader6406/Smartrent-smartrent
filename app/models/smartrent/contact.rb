module Smartrent
  class Contact < ActiveRecord::Base
    attr_accessible :email, :message, :name
    validates :email, :presence => true
    validates_presence_of :message, :name
    after_create do
      #send email
    end
  end
end
