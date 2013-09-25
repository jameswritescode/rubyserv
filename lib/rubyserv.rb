require 'yaml'
require 'pathname'
require 'socket'
require 'pry'
require 'logger'
require 'settingslogic'
require 'active_support/all'

require_relative 'rubyserv/helpers'
require_relative 'rubyserv/constants'
require_relative 'rubyserv/configuration'
require_relative 'rubyserv/logger'
require_relative 'rubyserv/protocol'
require_relative 'rubyserv/irc'
require_relative 'rubyserv/protocol/ts6'

module RubyServ
  def self.start!
    RubyServ::IRC.new(RubyServ.config.link.hostname, RubyServ.config.link.port)
  end
end
