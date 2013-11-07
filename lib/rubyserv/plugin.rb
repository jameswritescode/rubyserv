module RubyServ::Plugin
  def self.included(klass)
    RubyServ::PLUGINS << klass

    klass.send(:extend, ClassMethods)
    klass.send(:extend, klass)
  end

  class << self
    attr_accessor :protocol, :logger

    def load(plugin, user)
      rescue_exception(plugin, user, 'load') do
        return if plugin_already_loaded?(plugin, user)

        self.class.send(:load, RubyServ.root + "plugins/#{plugin.downcase}.rb")

        register(plugin)

        rubyserv.notice(user, "Plugin #{plugin} loaded.")
      end
    end

    def unload(plugin, user)
      rescue_exception(plugin, user, 'unload') do
        return if disallow_core_unload(plugin, user)

        plugin = RubyServ::PLUGINS.find { |klass| Kernel.const_get(plugin) == klass }
        plugin.client.quit("unloaded by #{user}")

        unregister(plugin)

        rubyserv.notice(user, "Plugin #{plugin} unloaded.")
      end
    end

    def reload(plugin, user)
      unload(plugin, user)
      load(plugin, user)
    end

    private

    def rescue_exception(plugin, user, type)
      begin
        yield
      rescue NameError
        rubyserv.notice(user, "Plugin #{plugin} does not exist, cannot #{type}.")
      rescue => ex
        rubyserv.notice(user, "There was a problem #{type}ing #{plugin}. Error: #{ex.message}")
      end
    end

    def register(plugin)
      plugin = Kernel.const_get(plugin)

      plugin.web_routes.each do |type, route, block, nickname|
        Sinatra::Application.send(type.to_sym, route, { plugin: plugin, service: nickname }, &block)
      end

      RubyServ::IRC.create_client(plugin, protocol.socket)
    end

    def unregister(plugin)
      plugin.matchers.clear
      plugin.events.clear
      plugin.callbacks.clear

      clear_sinatra_routes(plugin)

      plugin.web_routes.clear

      Sinatra::Application.destroy_methods_from(plugin)
      RubyServ::PLUGINS.delete(plugin)
    end

    def clear_sinatra_routes(plugin)
      plugin.web_routes.each do |web_route|
        types = [web_route.first.to_s.upcase]
        types << 'HEAD' if web_route.first == :get

        types.each do |type|
          Sinatra::Application.routes[type].delete_if do |sinatra_route|
            Sinatra::Base.send(:compile, web_route[1]).first == sinatra_route.first
          end
        end
      end
    end

    def rubyserv
      RubyServ::IRC::Client.find_by_nickname(Core.nickname)
    end

    def plugin_already_loaded?(plugin, user)
      if RubyServ::PLUGINS.include?(Kernel.const_get(plugin))
        rubyserv.notice(user, "The plugin #{plugin} is already loaded.")
        true
      else
        false
      end
    end

    def disallow_core_unload(plugin, user)
      if plugin == 'Core'
        rubyserv.notice(user, 'You cannot unload the Core plugin.')
        true
      else
        false
      end
    end
  end

  module ClassMethods
    attr_accessor :realname, :nickname, :hostname, :username, :prefix
    attr_writer   :connected
    attr_reader   :web_routes, :matchers, :events, :callbacks

    EVENTS = ['JOIN', 'PART', 'TMODE', 'KICK', 'PRIVMSG']

    def self.extended(klass)
      klass.instance_exec do
        @matchers, @events, @callbacks, @web_routes = [], [], [], []
        @connected = false

        set_configuration_defaults
      end
    end

    def set_configuration_defaults
      @hostname = RubyServ.config.rubyserv.hostname
      @username = RubyServ.config.rubyserv.username
      @realname = RubyServ.config.rubyserv.realname
      @channels = [RubyServ.config.rubyserv.channel]
      @prefix   = RubyServ.config.rubyserv.prefix
    end

    def before(method, options = {})
      options = { skip: false }.merge(options)

      @callbacks << [method, options, @nickname]
    end

    def configure(&block)
      yield self
    end

    def client
      RubyServ::IRC::Client.find_by_nickname(@nickname)
    end

    def channels
      @channels
    end

    def channels=(value)
      @channels.push(value).flatten! if value.is_a?(Array)
    end

    def match(pattern, options = {}, &block)
      options = { skip_prefix: false, skip_callbacks: false }.merge(options)

      @matchers << [pattern, options, block, @nickname]
    end

    def event(event, options = {}, &block)
      options = { skip_callbacks: false }.merge(options)

      @events << [event, options, block, @nickname]
    end

    def web(type, route, &block)
      @web_routes << [type, route, block, @nickname]
    end

    def __read(input)
      if input =~ /^:(\S+) PRIVMSG (\S+) :(.*)$/
        __read_matchers(OpenStruct.new(user: $1, target: $2, message: $3))
      end

      if input =~ /^:(\S+) (\S+) (\S+) (.*)$/
        target = $2 == 'PRIVMSG' ? $3 : $4.split.first

        __read_events(OpenStruct.new(user: $1, event: $2, target: target)) if EVENTS.include?($2)
      end
    end

    def __read_matchers(input)
      __get_matchers_for(input).each do |pattern, options, block, nickname|
        return unless __can_react?(nickname, input.target)

        if match = input.message.match(pattern)
          params  = match.captures
          message = __parse_message(input)

          __make_callbacks(:matchers, message) unless options[:skip_callbacks]

          block.call(message, *params)
        end
      end
    end

    def __read_events(input)
      __get_events_for(input.event).each do |_, options, block, nickname|
        return unless __can_react?(nickname, input.target)

        message = __parse_message(input)

        __make_callbacks(:events, message) unless options[:skip_callbacks]

        block.call(message)
      end
    end

    def __can_react?(nickname, target)
      service = RubyServ::IRC::Client.find_by_nickname(nickname)

      if target.start_with?('#')
        channel = RubyServ::IRC::Channel.find(target)
        channel.users.include?(service.user) ? true : false
      else
        target == service.uid ? true : false
      end
    end

    def __parse_message(input)
      RubyServ::Message.new(input, service: @nickname)
    end

    def __make_callbacks(type, message)
      @callbacks.each do |callback, options, nickname|
        skip     = options[:skip] ? options[:skip] : []
        callback = method(callback)

        unless skip.include?(type) || @nickname != nickname
          if !callback.arity.zero?
            callback.call(message)
          else
            callback.call
          end
        end
      end
    end

    def __get_matchers_for(input)
      if __prefix_used?(input.message) || __is_pm?(input.target)
        @matchers.select { |matcher| !matcher[1][:skip_prefix] }
      else
        @matchers.select { |matcher| matcher[1][:skip_prefix] }
      end
    end

    def __get_events_for(event)
      @events.select { |ary| ary.first.to_s == event.downcase }
    end

    def __is_pm?(target)
      target.include?('#') ? false : true
    end

    def __prefix_used?(message)
      message.start_with?(@prefix) || message =~ /^#{@nickname}(\W|_)/
    end

    def connected?
      @connected
    end
  end
end
