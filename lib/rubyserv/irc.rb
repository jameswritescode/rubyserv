class RubyServ::IRC
  attr_reader :protocol

  @connected = false
  @logger    = RubyServ::Logger.new($stderr)

  def initialize(link_config, args)
    @server   = link_config.hostname
    @port     = link_config.port
    @cli_args = args
    @logger   = self.class.logger

    start
  rescue NameError => ex
    puts ex
  end

  class << self
    attr_writer :connected
    attr_reader :logger

    def connected?
      @connected
    end

    def create_client(plugin, socket)
      if nickname_collision?(plugin)
        @logger.warn "Plugin #{plugin} not loaded because a #{plugin.nickname} already exists."
      else
        RubyServ::IRC::Client.create(socket, @logger,
          nickname: plugin.nickname,
          hostname: plugin.hostname,
          username: plugin.username,
          realname: plugin.realname,
          modes:    'Sio'
        )

        plugin.channels.each { |channel| plugin.client.join(channel, true) }
        plugin.connected = true
      end
    end

    def nickname_collision?(plugin)
      !RubyServ::IRC::User.find_by_nickname(plugin.nickname).nil?
    end
  end

  def start
    create_socket
    define_protocol

    Thread.new { start_sinatra_app } if RubyServ.config.web.enabled

    if @cli_args.include?('-debug')
      connect_to_irc
    else
      Thread.new { connect_to_irc }
      binding.pry
    end
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
    @protocol = Kernel.const_get('RubyServ').const_get('Protocol').const_get(RubyServ.config.link.protocol).new(@socket, @logger)

    RubyServ::Plugin.protocol = @protocol
    RubyServ::Plugin.logger   = @logger
  end

  def generate_sinatra_routes
    RubyServ::PLUGINS.each do |plugin|
      plugin.web_routes.each do |type, route, block, nickname|
        Sinatra::Application.send(type.to_sym, route, { service: nickname }, &block)
      end
    end
  end

  def start_sinatra_app
    generate_sinatra_routes

    Sinatra::Application.set(:port, RubyServ.config.web.port)
    Sinatra::Application.run!
  end

  def rescue_exception
    begin
      yield
    rescue => e
      @logger.exception(e)
    end
  end

  def connect_to_irc
    @protocol.authenticate

    loop do
      rescue_exception do
        output = @socket.gets.strip

        @logger.incoming "#{output}\r\n"

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
  end

  def create_clients
    @logger.info 'Creating RubyServ and other clients'

    RubyServ::PLUGINS.each { |plugin| self.class.create_client(plugin, @socket) }

    clean_bad_plugins

    @clients_created = true
  end

  def clean_bad_plugins
    RubyServ::PLUGINS.each { |plugin| RubyServ::PLUGINS.delete(plugin) unless plugin.connected? }
  end
end
