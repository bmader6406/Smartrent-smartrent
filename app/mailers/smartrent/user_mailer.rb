module Smartrent
  class UserMailer < ApplicationMailer
    def contact_email(contact)
      @contact = contact
      mail(:from => "alerts@hy.ly", to: DEFAULT_EMAIL, subject: "[BozzutoSmartrent] Message from #{@contact.name} on contact form", bcc: "tn@hy.ly")
    end
  end
end
