class RubyServ::Message
  def initialize(input, options = {})
    @input  = input
    @client = RubyServ::IRC::Client.find_by_nickname(options[:service])
  end

  def user
    @input.nil? ? nil : RubyServ::IRC::User.find(@input.user)
  end

  def reply(msg)
    @input.nil? ? nil: @client.message(@input.target, msg)
  end

  def client
    @client
  end

  def Channel
    RubyServ::IRC::Channel
  end

  def User
    RubyServ::IRC::User
  end

  def Server
    RubyServ::IRC::Server
  end

  def Client
    RubyServ::IRC::Client
  end
end
