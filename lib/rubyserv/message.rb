class RubyServ::Message
  def initialize(input, options = {})
    @input  = input
    @client = RubyServ::IRC::Client.find_by_nickname(options[:service]).first
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
end
