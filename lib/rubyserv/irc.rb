class RubyServ::IRC
  attr_reader :protocol

  def initialize(server, port)
    @server    = server
    @port      = port
    @buffer    = []
    @connected = false

    start
  rescue NameError
    puts "Invalid protocol: #{RubyServ.config.link.protocol}"
  end

  def start
    create_socket
    define_protocol
    connect_to_irc
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
      puts @socket.gets
    end
  end

  def send(text)
    puts ">> #{text}"

    @socket.puts text
  end
end
