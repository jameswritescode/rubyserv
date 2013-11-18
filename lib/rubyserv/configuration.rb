module RubyServ
  class Configuration < Settingslogic
    source RubyServ.root.join('config', 'rubyserv.yml')
  end

  def self.config
    Configuration
  end
end
