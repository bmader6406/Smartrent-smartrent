module Smartrent
  class ResidentMailer < ApplicationMailer
    def password_change(resident)
      @resident = resident
      mail(from: 'Bozzuto SmartRent <no-reply@bozzuto.com>', to: resident.email, subject: "Your password has been changed")
    end
  end
end
