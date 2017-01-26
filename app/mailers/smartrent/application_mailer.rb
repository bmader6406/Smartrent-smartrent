module Smartrent
  class ApplicationMailer < ActionMailer::Base
    default from: SMARTRENT_EMAIL
    default :return_path => OPS_EMAIL
  end
end
