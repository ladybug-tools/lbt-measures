source 'http://rubygems.org'

# Specify your gem's dependencies
gemspec

# get the openstudio-extension gem
if File.exist?('../OpenStudio-extension-gem')  # local development copy
  gem 'openstudio-extension', path: '../OpenStudio-extension-gem'
else  # get it from rubygems.org
  gem 'openstudio-extension', '0.4.2'
end
