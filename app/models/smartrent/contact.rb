module Smartrent
  class Contact < ActiveRecord::Base

    validates :email, :message, :name, :presence => true
    
    after_create :send_email
    before_validation :sanitize_xss

    def sanitize_xss
      self.attributes.each do |key, value|
        self[key] = ActionView::Base.full_sanitizer.sanitize(self[key]) if self[key].is_a? String
        self[key] = self[key].strip if self[key].respond_to?("strip")
      end
    end
    
    private
    
      def send_email
        Smartrent::UserMailer.contact_email(self).deliver_now
      end
  end
end
