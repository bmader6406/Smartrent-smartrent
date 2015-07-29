module Smartrent
  class Contact < ActiveRecord::Base

    validates :email, :message, :name, :presence => true
    
    after_create :send_email
    
    private
    
      def send_email
        Smartrent::UserMailer.contact_email(self).deliver_now
      end
  end
end
