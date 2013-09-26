class RubyServ::Protocol
  def initialize(socket)
    @socket = socket
  end

  [:authenticate, :create_clients, :ping,
  :verify_authentication, :handle_server, :handle_user,
  :handle_channel].each do |name|
    define_method(name) { |input| raise "##{name} must be defined in the protocol" }
  end

  def send(text)
    puts ">> #{text}"

    @socket.puts "#{text}\r"
  end
end
