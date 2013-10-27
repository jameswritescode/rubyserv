class RubyServ::IRC
  attr_reader :protocol

  @connected = false

  def initialize(link_config)
    @server = link_config.hostname
    @port   = link_config.port

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
    Thread.new { connect_to_irc }
    Thread.new { start_sinatra_app if RubyServ.config.web.enabled }
    binding.pry
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

  def generate_sinatra_routes
    # This is dirty and I don't like it, but I don't know of a better way at
    # this time.
    RubyServ::PLUGINS.each do |plugin|
      plugin.web_routes.each do |type, route, block|
        type = type.to_s.upcase
        Sinatra::Application.routes[type] ||= []
        Sinatra::Application.routes[type] << [/\A#{::Regexp.new(route).source}\z/, [], [], block]
      end
    end
  end

  def start_sinatra_app
    generate_sinatra_routes

    Sinatra::Application.set(:port, RubyServ.config.web.port)
    Sinatra::Application.run!
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
      @protocol.handle_client_commands(output) if @clients_created

      create_clients if self.class.connected? && !@clients_created
    end
  end

  def create_clients
    puts '>> Creating RubyServ and other clients'

    RubyServ::PLUGINS.each do |plugin|
      create_client(plugin)
    end

    instance_variable_set(:@clients_created, true)
  end

  def create_client(plugin)
    RubyServ::IRC::Client.create(@socket,
      nickname: plugin.nickname,
      hostname: plugin.hostname,
      username: plugin.username,
      realname: plugin.realname,
      modes:    'Sio'
    )

    plugin.channels.each do |channel|
      RubyServ::IRC::Client.find_by_nickname(plugin.nickname).first.join(channel, true)
    end

    plugin.connected = true
  end
end
