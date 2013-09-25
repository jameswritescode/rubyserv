class RubyServ::Protocol
  def initialize(socket)
    @socket = socket
  end

  [:authenticate, :create_clients].each do |name|
    define_method(name) { raise "##{name} must be defined in the protocol" }
  end

  def send(text)
    puts ">> #{text}"

    @socket.puts text
  end
end
