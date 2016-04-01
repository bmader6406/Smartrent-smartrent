module Smartrent
  class ApplicationMailer < ActionMailer::Base
    default from: "smartrent@bozzuto.com"
    default :return_path => "ses@hy.ly"
  end
end
