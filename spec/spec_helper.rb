require File.expand_path('../lib/rubyserv', File.dirname(__FILE__))
require 'fakefs/spec_helpers'

Dir[File.expand_path('..', File.dirname(__FILE__)) + '../spec/support/**/*.rb'].each { |f| require f }
