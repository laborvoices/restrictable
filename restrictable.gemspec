$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "restrictable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "restrictable"
  s.version     = Restrictable::VERSION
  s.authors     = ["Brookie Guzder-Williams"]
  s.email       = ["brook.williams@gmail.com"]
  s.summary     = "Add user roles and restricts access to data based on those roles."
  s.description = "Add user roles and restricts access to data based on those roles."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ['>= 4.0', '< 5.0']

  s.add_development_dependency "pg"
  s.add_development_dependency "rspec-rails"
end
