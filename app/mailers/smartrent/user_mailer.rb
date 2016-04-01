module Smartrent
  class UserMailer < ApplicationMailer
    def contact_email(contact)
      @contact = contact
      mail(to: DEFAULT_EMAIL, subject: "[BozzutoSmartrent] Message from #{@contact.name} on contact form")
    end
  end
end
