module RubyServ
  class Configuration < Settingslogic
    source RubyServ.root.join('etc', 'rubyserv.yml')
  end

  def self.config
    Configuration
  end
end