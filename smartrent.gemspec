$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "smartrent/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "smartrent"
  s.version     = Smartrent::VERSION
  s.authors = ["Hy.ly"]
  s.email = ["help@hy.ly"]
  s.homepage    = ""
  s.summary     = ""
  s.description = ""

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "4.2.2"
  s.add_dependency "devise", "~> 3.5.1"
  s.add_dependency "js-routes", "~> 1.0.1"
  s.add_dependency "aws-sdk", "~> 1.9.5"
  #s.add_dependency "ransack" # make ransack use polyamorous 1.1
  s.add_dependency "mandrill-api", "~> 1.0.53"
  s.add_dependency "smarter_csv", "~> 1.0.19"
  s.add_dependency "will_paginate-bootstrap", "~> 1.0.1"
  s.add_dependency "geocoder", "~> 1.2.9"
  s.add_dependency "squeel", "~> 1.2.3"
  s.add_dependency "htmlentities", "~> 4.3.4"
  s.add_dependency "delayed_paperclip"
  s.add_dependency "resque"
  s.add_dependency "delayed_job_active_record"
  #s.add_dependency "prettyphoto-rails", "~> 0.2.1" #this gem is out of date, don't use it any more
end
