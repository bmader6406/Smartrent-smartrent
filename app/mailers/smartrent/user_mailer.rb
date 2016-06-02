module Smartrent
  class UserMailer < ApplicationMailer
    def contact_email(contact)
      @contact = contact
      mail(:from => "noreply@hy.ly", to: DEFAULT_EMAIL, subject: "[BozzutoSmartrent] Message from #{@contact.name} on contact form", reply_to: @contact.email, bcc: "tn@hy.ly")
    end
  end
end
