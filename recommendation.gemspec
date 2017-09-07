$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "recommendation/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "recommendation"
  s.version     = Recommendation::VERSION
  s.authors     = ["James Page"]
  s.email       = ["james.page@cd2solutions.co.uk"]
  s.homepage    = "https://cd2solutions.co.uk/"
  s.summary     = "Summary of Recommendation."
  s.description = "Description of Recommendation."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.1.3"

  s.add_development_dependency "pg"
end
