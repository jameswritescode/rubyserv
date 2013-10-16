class RubyServ::IRC
  attr_reader :protocol

  @connected = false

  def initialize(server, port)
    @server    = server
    @port      = port

    start
  rescue NameError => ex
    puts ex
  end

  class << self
    attr_writer :connected

    def connected?
      @connected
    end
  end

  def start
    create_socket
    define_protocol
    connect_to_irc
  end

  def create_socket
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

      @protocol.handle_errors(output)
      @protocol.handle_server(output)
      @protocol.handle_user(output)
      @protocol.handle_channel(output)
      @protocol.handle_ping(output)
      @protocol.handle_whois(output)

      if self.class.connected? && !@clients_created
        create_clients
      end
    end
  end

  def create_clients
    puts '>> Creating RubyServ and other clients'

    RubyServ::IRC::Client.create(@socket,
      nickname: RubyServ.config.rubyserv.nickname,
      hostname: RubyServ.config.rubyserv.hostname,
      username: RubyServ.config.rubyserv.username,
      realname: RubyServ.config.rubyserv.realname,
      modes:    'Sio'
    )

    RubyServ::IRC::Client.all.each do |client|
      client.join(RubyServ.config.rubyserv.channel, true)
    end

    instance_variable_set(:@clients_created, true)
  end

  def send(text)
    puts ">> #{text}"

    @socket.puts "#{text}\r"
  end
end
