class RubyServ::IRC
  attr_reader :protocol

  def initialize(server, port)
    @server    = server
    @port      = port
    @connected = false

    start
  rescue NameError => ex
    puts ex
  end

  def start
    create_socket
    define_protocol
    Thread.new { connect_to_irc }
    binding.pry
  end

  def create_socket
    return @socket if @connected

    @socket = TCPSocket.new(@server, @port)

    if RubyServ.config.link.ssl
      require 'openssl'

      context             = OpenSSL::SSL::SSLContext.new
      context.verify_mode = OpenSSL::SSL::VERIFY_NONE

      @socket            = OpenSSL::SSL::SSLSocket.new(socket, context)
      @socket.sync_close = true
      @socket.connect
    end
  end

  def define_protocol
    @protocol = Kernel.const_get("RubyServ::Protocol::#{RubyServ.config.link.protocol}").new(@socket)
  end

  def connect_to_irc
    @protocol.authenticate

    while true
      output = @socket.gets.strip

      puts "#{output}\r\n"

      @protocol.verify_authentication(output)
      @protocol.handle_server(output)
      @protocol.handle_user(output)
      @protocol.handle_channel(output)
      @protocol.pong(output)
    end
  end

  def send(text)
    puts ">> #{text}"

    @socket.puts "#{text}\r"
  end
end
