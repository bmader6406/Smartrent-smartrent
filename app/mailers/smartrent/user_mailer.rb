module Smartrent
  class UserMailer < ApplicationMailer
    def contact_email(contact)
      @contact = contact
      mail(:from => "CRM Alerts <#{OPS_EMAIL}>", to: SMARTRENT_EMAIL, subject: "[BozzutoSmartrent] Message from #{@contact.name} on contact form", reply_to: @contact.email, bcc: ADMIN_EMAIL)
    end
  end
end
