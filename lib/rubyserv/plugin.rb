module RubyServ::Plugin
  def self.included(klass)
    RubyServ::PLUGINS << klass

    klass.send(:extend, ClassMethods)
    klass.send(:extend, klass)
  end

  module ClassMethods
    attr_accessor :realname, :nickname, :hostname, :username
    attr_reader   :matchers
    attr_writer   :connected

    EVENTS = ['JOIN', 'PART', 'TMODE', 'KICK', 'PRIVMSG']

    def self.extended(klass)
      klass.instance_exec do
        @matchers, @events, @callbacks, @web_routes = [], [], [], []

        @connected = false

        @hostname = RubyServ.config.rubyserv.hostname
        @username = RubyServ.config.rubyserv.username
        @realname = RubyServ.config.rubyserv.realname
        @channels = [RubyServ.config.rubyserv.channel]
      end
    end

    def before_match(method)
      @callbacks << method
    end

    def configure(&block)
      yield self
    end

    def channels
      @channels
    end

    def channels=(value)
      @channels.push(value).flatten! if value.is_a?(Array)
    end

    def match(pattern, options = {}, &block)
      options = { prefix: true }.merge(options)

      @matchers << [pattern, options, block]
    end

    def event(event, options = {}, &block)
      @events << [event, block]
    end

    def web(type, route, &block)
      @web_routes << [type, route, block]
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
      __get_matchers_for(input.message).each do |pattern, options, block|
        if match = input.message.match(pattern)
          params = match.captures

          __make_callbacks

          block.call(__parse_message(input), *params)
        end
      end
    end

    def __read_events(input)
      __get_events_for(input.event).each do |_, block|
        __make_callbacks

        block.call(__parse_message(input))
      end
    end

    def __parse_message(input)
      RubyServ::Message.new(input, service: @nickname)
    end

    def __make_callbacks
      @callbacks.each { |callback| method(callback).call }
    end

    def __get_matchers_for(message)
      if __prefix_used?(message)
        @matchers.select { |matcher| matcher[1][:prefix] }
      else
        @matchers.select { |matcher| !matcher[1][:prefix] }
      end
    end

    def __get_events_for(event)
      @events.select { |ary| ary.first.to_s == event.downcase }
    end

    def __prefix_used?(message)
      message.start_with?(RubyServ.config.rubyserv.prefix) || message =~ /^#{@nickname}(\W|_)/
    end

    def connected?
      @connected
    end
  end
end
