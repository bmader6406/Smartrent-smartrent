$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "smartrent/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "smartrent"
  s.version     = Smartrent::VERSION
  s.authors     = ["Chon Doan"]
  s.email       = ["domich.dt@gmail.com"]
  s.homepage    = "http://mygem.com"
  s.summary     = "Summary of Smartrent."
  s.description = "Description of Smartrent."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.13"

  s.add_dependency "pg"
  s.add_dependency "devise"
  s.add_dependency 'omniauth'
  s.add_dependency "jquery-rails"
  s.add_dependency "therubyracer"
  s.add_dependency "less-rails"
  s.add_dependency "twitter-bootstrap-rails"
  s.add_dependency "paperclip"
  s.add_dependency "will_paginate"
  s.add_dependency "js-routes"
  s.add_dependency "aws-sdk", "< 2.0"
  s.add_dependency "ransack"
  s.add_dependency "mandrill-api"
  s.add_dependency "smarter_csv"
  s.add_dependency "mysql2"
  s.add_dependency "will_paginate-bootstrap"
  s.add_dependency "geocoder"
  s.add_dependency "squeel"
  s.add_dependency "htmlentities"
end
