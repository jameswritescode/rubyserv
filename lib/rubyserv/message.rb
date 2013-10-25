class RubyServ::Message
  def initialize(input, options = {})
    @input  = input
    @client = RubyServ::IRC::Client.find_by_nickname(options[:service]).first
  end

  def user
    RubyServ::IRC::User.find(@input.user)
  end

  def reply(msg)
    @client.message(@input.target, msg)
  end
end
