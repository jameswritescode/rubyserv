module RubyServ::Plugin
  def self.included(klass)
    RubyServ::PLUGINS << klass

    klass.send(:extend, ClassMethods)
    klass.send(:extend, klass)
  end

  module ClassMethods
    attr_accessor :realname, :nickname, :hostname, :username
    attr_writer   :connected
    attr_reader   :web_routes

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
      options = { prefix: true, skip_callbacks: false }.merge(options)

      @matchers << [pattern, options, block, @nickname]
    end

    def event(event, options = {}, &block)
      options = { skip_callbacks: false }.merge(options)

      @events << [event, options, block, @nickname]
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
      __get_matchers_for(input).each do |pattern, options, block, nickname|
        return unless __can_react?(nickname, input.target)

        if match = input.message.match(pattern)
          params = match.captures

          __make_callbacks unless options[:skip_callbacks]

          block.call(__parse_message(input), *params)
        end
      end
    end

    def __read_events(input)
      __get_events_for(input.event).each do |_, options, block, nickname|
        return unless __can_react?(nickname, input.target)

        __make_callbacks unless options[:skip_callbacks]

        block.call(__parse_message(input))
      end
    end

    def __can_react?(nickname, target)
      service = RubyServ::IRC::Client.find_by_nickname(nickname).first.user

      if target.start_with?('#')
        channel = RubyServ::IRC::Channel.find(target)
        channel.users.include?(service) ? true : false
      else
        target == @nickname ? true : false
      end
    end

    def __parse_message(input)
      RubyServ::Message.new(input, service: @nickname)
    end

    def __make_callbacks
      @callbacks.each { |callback| method(callback).call }
    end

    def __get_matchers_for(input)
      if __prefix_used?(input.message) || __is_pm?(input.target)
        @matchers.select { |matcher| matcher[1][:prefix] }
      else
        @matchers.select { |matcher| !matcher[1][:prefix] }
      end
    end

    def __get_events_for(event)
      @events.select { |ary| ary.first.to_s == event.downcase }
    end

    def __is_pm?(target)
      target.include?('#') ? false : true
    end

    def __prefix_used?(message)
      message.start_with?(RubyServ.config.rubyserv.prefix) || message =~ /^#{@nickname}(\W|_)/
    end

    def connected?
      @connected
    end
  end
end
