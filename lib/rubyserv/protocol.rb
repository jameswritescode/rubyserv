class RubyServ::Protocol
  def initialize(socket)
    @socket = socket
  end

  [:authenticate, :handle_ping, :verify_authentication,
   :handle_server, :handle_user, :handle_channel,
   :handle_errors, :handle_whois].each do |name|
    define_method(name) { |input| raise "##{name} must be defined in the protocol" }
  end

  def handle_client_commands(input)
    RubyServ::PLUGINS.each do |plugin|
      plugin.read(input) if plugin.connected?
    end
  end

  def send_raw(text)
    puts ">> #{text}"

    sleep(0.05)
    @socket.puts "#{text}\r"
  end
end
