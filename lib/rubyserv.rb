require 'yaml'
require 'pathname'
require 'socket'
require 'pry'

module RubyServ
  def self.root
    Pathname.new(File.dirname(__FILE__) + '/..').expand_path
  end

  def self.config
    YAML.load_file("#{self.root}/etc/rubyserv.yml")
  end
end

require_relative 'rubyserv/constants'
require_relative 'rubyserv/irc'
require_relative 'rubyserv/protocols/ts6'
