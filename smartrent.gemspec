$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "smartrent/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "smartrent"
  s.version     = Smartrent::VERSION
  s.authors     = ["Chon Doan"]
  s.email       = ["domich.dt@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Smartrent."
  s.description = "TODO: Description of Smartrent."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.13"

  s.add_dependency "mysql2"
  s.add_dependency "devise"
  s.add_dependency 'omniauth'
end
