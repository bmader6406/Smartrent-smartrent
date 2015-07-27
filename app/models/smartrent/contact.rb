module Smartrent
  class Contact < ActiveRecord::Base
    #attr_accessible :email, :message, :name
    validates :email, :presence => true
    validates_presence_of :message, :name
    
    after_create :send_email
    
    private
    
      def send_email
        Smartrent::UserMailer.contact_email(self).deliver_now
      end
  end
end
