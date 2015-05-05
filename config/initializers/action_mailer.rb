if Rails.env == "development"
  ActionMailer::Base.default_url_options = {:host => "http://localhost:3000"}
else
  ActionMailer::Base.default_url_options = {:host => "https://smartrent-dev.herokuapp.com"}
end
