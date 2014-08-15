module RubyServ::Plugin
  def self.included(klass)
    RubyServ::PLUGINS << klass

    klass.send(:extend, ClassMethods)
    klass.send(:extend, klass)
  end

  class << self
    attr_accessor :protocol

    def load_plugin(plugin, user)
      rescue_exception(plugin, user, 'load') do
        return if plugin_already_loaded?(plugin, user)

        load(RubyServ.root.join('plugins', plugin.downcase, "#{plugin.downcase}.rb"))

        register(plugin)

        rubyserv.notice(user, "Plugin #{plugin} loaded.")
      end
    end

    def unload_plugin(plugin, user)
      rescue_exception(plugin, user, 'unload') do
        return if disallow_core_unload(plugin, user)

        plugin = RubyServ::PLUGINS.find { |klass| Kernel.const_get(plugin) == klass }
        plugin.client.quit("unloaded by #{user}")

        unregister(plugin)

        rubyserv.notice(user, "Plugin #{plugin} unloaded.")

        Object.send(:remove_const, plugin.name.to_sym)
      end
    end

    def reload_plugin(plugin, user)
      unload_plugin(plugin, user)
      load_plugin(plugin, user)
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
      Sinatra::Application.clear_plugin_routes(plugin)
      RubyServ::Matcher.unregister(plugin)
      Sinatra::Application.destroy_methods_from(plugin)
      RubyServ::PLUGINS.delete(plugin)
    end

    def rubyserv
      RubyServ::IRC::Client.find_by_nickname(Core.nickname)
    end

    def plugin_already_loaded?(plugin, user)
      begin
        if RubyServ::PLUGINS.include?(Kernel.const_get(plugin))
          rubyserv.notice(user, "The plugin #{plugin} is already loaded.")
          true
        else
          false
        end
      rescue
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
    attr_accessor :realname, :nickname, :hostname, :username, :prefix, :database
    attr_writer   :connected

    def self.extended(klass)
      klass.instance_exec do
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
      options = { skip: [] }.merge(options)

      RubyServ::Matcher.add(:callback, self, method, options)
    end

    def configure
      yield self
    end

    def database_setup
      return if RubyServ::Database.exist?(@database)

      yield RubyServ::Database.open(@database)
    end

    def database
      RubyServ::Database.open(@database)
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

      RubyServ::Matcher.add(:matcher, self, pattern, options, block)
    end

    def event(event, options = {}, &block)
      options = { skip_callbacks: false }.merge(options)

      RubyServ::Matcher.add(:event, self, event, options, block)
    end

    def web(type, route, &block)
      RubyServ::Matcher.add(:route, self, type, route, block)
    end

    def call(input)
      if input =~ /^:(\S+) PRIVMSG (\S+) :(.*)$/
        RubyServ::Matcher.read_matchers(OpenStruct.new(user: $1, target: $2, message: $3, plugin: self))
      end

      if input =~ /^:(\S+) (\S+) (\S+) (.*)$/
        target = $2 == 'PRIVMSG' ? $3 : $4.split.first

        RubyServ::Matcher.read_events(OpenStruct.new(user: $1, event: $2, target: target, plugin: self))
      end
    end

    def connected?
      @connected
    end
  end
end
