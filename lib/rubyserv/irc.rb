class RubyServ::IRC
  attr_reader :protocol

  @connected = false

  def initialize(link_config, args)
    @server   = link_config.hostname
    @port     = link_config.port
    @cli_args = args

    start
  rescue NameError => ex
    puts ex
  end

  class << self
    attr_writer :connected

    def connected?
      @connected
    end

    def create_client(plugin, socket)
      return if handle_nickname_collision(plugin)

      RubyServ::IRC::Client.create(socket,
        nickname: plugin.nickname,
        hostname: plugin.hostname,
        username: plugin.username,
        realname: plugin.realname,
        modes:    'Sio'
      )

      plugin.channels.each { |channel| plugin.client.join(channel, true) }
      plugin.connected = true
    end

    def handle_nickname_collision(plugin)
      if nickname_collision?(plugin)
        RubyServ::Logger.warn "Plugin #{plugin} not loaded because a user with nick #{plugin.nickname} already exists."
        true
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

    if @cli_args.include?('-debug') || @cli_args.include?('-daemon')
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
    @protocol = Kernel.const_get('RubyServ').const_get('Protocol').const_get(RubyServ.config.link.protocol).new(@socket)

    RubyServ::Plugin.protocol = @protocol
  end

  def generate_sinatra_routes
    RubyServ::PLUGINS.each do |plugin|
      Sinatra::Application.inject_plugin_routes(plugin)
    end
  end

  def start_sinatra_app
    generate_sinatra_routes

    Sinatra::Application.set(:port, RubyServ.config.web.port)
    Sinatra::Application.set(:logging, RubyServ::Logger)
    Sinatra::Application.run!
  end

  def rescue_exception
    begin
      yield
    rescue => e
      RubyServ::Logger.exception(e)
    end
  end

  def connect_to_irc
    @protocol.authenticate

    loop do
      rescue_exception do
        output = @socket.gets.strip

        RubyServ::Logger.incoming "#{output}\r\n"

        @protocol.handle_incoming(output)
        @protocol.handle_client_commands(output) if @clients_created

        create_clients if self.class.connected? && !@clients_created
      end
    end
  end

  def create_clients
    RubyServ::Logger.info 'Creating RubyServ and other clients'

    RubyServ::PLUGINS.each { |plugin| self.class.create_client(plugin, @socket) }

    clean_bad_plugins

    @clients_created = true
  end

  def clean_bad_plugins
    RubyServ::PLUGINS.each { |plugin| RubyServ::PLUGINS.delete(plugin) unless plugin.connected? }
  end
end
