source 'https://rubygems.org'

gem 'rake'
gem 'pry'
gem 'settingslogic'

# This evals a Gemfile_local file that you can put define dependencies for your
# RubyServ plugins.
local_gemfile = File.expand_path('../Gemfile_local', __FILE__)
eval File.read(local_gemfile) if File.exists?(local_gemfile)
