class RubyServ::Protocol
  def initialize(socket)
    @socket = socket
  end

  [:authenticate, :handle_ping, :verify_authentication,
   :handle_server, :handle_user, :handle_channel,
   :handle_errors].each do |name|
    define_method(name) { |input| raise "##{name} must be defined in the protocol" }
  end

  def send(text)
    puts ">> #{text}"

    @socket.puts "#{text}\r"
  end
end
