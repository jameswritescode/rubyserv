class RubyServ::Logger < Logger
  attr_accessor :channel

  def initialize
    super

    self.channel = RubyServ.config.rubyserv.channel
  end
end
