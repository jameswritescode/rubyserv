require 'yaml'
require 'pathname'

module RubyServ
  def self.root
    Pathname.new(File.dirname(__FILE__) + '/..').expand_path
  end

  def self.config
    YAML.load_file("#{self.root}/etc/rubyserv.yml")
  end
end

require_relative 'rubyserv/constants'
