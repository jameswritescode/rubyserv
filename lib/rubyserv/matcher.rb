module RubyServ::Matcher
  EVENTS = ['JOIN', 'PART', 'TMODE', 'KICK', 'PRIVMSG']

  class << self
    def add(type, plugin, *args)
      initialize_matcher_variables_for(plugin)

      @data[plugin]["#{type}s".to_sym] << args
    end

    def call(plugin, type)
      @data[plugin][type]
    end

    def unregister(plugin)
      @data[plugin].delete
    end

    def read_matchers(object)
      matchers_for(object).each do |pattern, options, block|
        next unless can_react?(object.plugin.nickname, object.target)

        if match = object.message.match(pattern)
          params  = match.captures
          message = RubyServ::Message.new(object, service: object.plugin.nickname)

          make_callbacks(:matchers, message, object.plugin) unless options[:skip_callbacks]

          block.call(message, *params)
        end
      end
    end

    def read_events(object)
      return unless EVENTS.include?(object.event)

      @data[object.plugin][:events].each do |event, options, block|
        next unless event == object.event
        next unless can_react?(object.plugin.nickname, object.target)

        message = RubyServ::Message.new(object, service: object.plugin.nickname)

        make_callbacks(:events, message, object.plugin) unless options[:skip_callbacks]

        block.call(message)
      end
    end

    private

    def matchers_for(object)
      matchers = if !object.target.start_with?('#')
                   @data[object.plugin][:matchers].select { |matcher| !matcher[1][:skip_prefix] }
                 elsif object.message.start_with?(object.plugin.prefix) || object.message =~ /\A#{object.plugin.nickname}(\W|_)/
                   @data[object.plugin][:matchers].map do |pattern, options, block|
                     [Regexp.new(Regexp.escape(object.plugin.prefix) + pattern.source), options, block]
                   end.select { |matcher| !matcher[1][:skip_prefix] }
                 else
                   []
                 end

      @data[object.plugin][:matchers].select { |matcher| matcher[1][:skip_prefix] }.each { |matcher| matchers << matcher }

      matchers
    end

    def make_callbacks(type, message, plugin)
      @data[plugin][:callbacks].each do |callback, options|
        callback = method(callback)

        unless options[:skip].include?(type)
          !callback.arity.zero? ? callback.call(message) : callback.call
        end
      end
    end

    def can_react?(nickname, target)
      service = RubyServ::IRC::Client.find_by_nickname(nickname)

      if target.start_with?('#')
        RubyServ::IRC::Channel.find(target).users.include?(service.user)
      else
        target == service.uid
      end
    end

    def initialize_matcher_variables_for(plugin)
      @data ||= {}

      @data[plugin] ||= {
        matchers:  [],
        events:    [],
        callbacks: [],
        routes:    []
      }
    end
  end
end
