module Smartrent
  class ApplicationMailer < ActionMailer::Base
    default from: DEFAULT_EMAIL
    layout 'mailer'
  end
end
