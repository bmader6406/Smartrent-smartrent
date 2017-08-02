module Smartrent
  class Contact < ActiveRecord::Base

    validates :email, :message, :name, :presence => true
    
    after_create :send_email
    before_validation :sanitize_xss

    def sanitize_xss
      SanitizeXss.sanitize(self)
    end
    
    private
    
      def send_email
        Smartrent::UserMailer.contact_email(self).deliver_now
      end
  end
end
