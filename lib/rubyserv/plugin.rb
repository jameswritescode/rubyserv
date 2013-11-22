module RubyServ::Plugin
  def self.included(klass)
    RubyServ::PLUGINS << klass

    klass.send(:extend, ClassMethods)
    klass.send(:extend, klass)
  end

  class << self
    attr_accessor :protocol

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

      Sinatra::Application.inject_plugin_routes(plugin)
      RubyServ::IRC.create_client(plugin, protocol.socket)
    end

    def unregister(plugin)
      plugin.matchers.clear
      plugin.events.clear
      plugin.callbacks.clear

      Sinatra::Application.clear_plugin_routes(plugin)

      plugin.web_routes.clear

      Sinatra::Application.destroy_methods_from(plugin)
      RubyServ::PLUGINS.delete(plugin)
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

      @callbacks << [method, options, self]
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

      @matchers << [pattern, options, block, self]
    end

    def event(event, options = {}, &block)
      options = { skip_callbacks: false }.merge(options)

      @events << [event, options, block, self]
    end

    def web(type, route, &block)
      @web_routes << [type, route, block, self]
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
      __get_matchers_for(input).each do |pattern, options, block, plugin|
        return unless __can_react?(plugin.nickname, input.target)

        if match = input.message.match(pattern)
          params  = match.captures
          message = __parse_message(input)

          __make_callbacks(:matchers, message) unless options[:skip_callbacks]

          block.call(message, *params)
        end
      end
    end

    def __read_events(input)
      __get_events_for(input.event).each do |_, options, block, plugin|
        return unless __can_react?(plugin.nickname, input.target)

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
      @callbacks.each do |callback, options, plugin|
        skip     = options[:skip] ? options[:skip] : []
        callback = method(callback)

        unless skip.include?(type) || @nickname != plugin.nickname
          !callback.arity.zero? ? callback.call(message) : callback.call
        end
      end
    end

    def __get_matchers_for(input)
      matchers = []

      if __is_pm?(input.target)
        matchers = @matchers.select { |matcher| !matcher[1][:skip_prefix] }
      elsif __prefix_used?(input.message)
        matchers = __matchers_with_prefix.select { |matcher| !matcher[1][:skip_prefix] }
      end

      no_prefix = @matchers.select { |matcher| matcher[1][:skip_prefix] }
      no_prefix.each { |matcher| matchers << matcher } unless no_prefix.empty?

      matchers
    end

    def __matchers_with_prefix
      prefix_matchers = []

      @matchers.each do |matcher|
        prefix_matchers << matcher.dup
        prefix_matchers.last[0] = Regexp.new(Regexp.escape(@prefix) + matcher[0].source)
      end

      prefix_matchers
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
