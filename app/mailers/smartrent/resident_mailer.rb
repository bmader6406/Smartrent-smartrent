module Smartrent
  class ResidentMailer < ApplicationMailer
    def password_change(resident)
      @resident = resident
      mail(from: 'Bozzuto Smartrent <no-reply@bozzuto.com>', to: resident.email, subject: "Your password has been changed")
    end
  end
end
