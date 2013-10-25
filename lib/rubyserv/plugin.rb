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

    def self.extended(klass)
      klass.instance_exec do
        @matchers  = []

        @connected = false

        @hostname = RubyServ.config.rubyserv.hostname
        @username = RubyServ.config.rubyserv.username
        @realname = RubyServ.config.rubyserv.realname
        @channels = [RubyServ.config.rubyserv.channel]
      end
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

    def read(input)
      if input =~ /^:(\S+) PRIVMSG (\S+) :(.*)$/
        input = OpenStruct.new(user: $1, target: $2, message: $3)

        get_matchers_for(input.message).each do |matcher|
          if match = input.message.match(matcher.first)
            message = RubyServ::Message.new(input, service: @nickname)
            params  = match.captures

            matcher.last.call(message, *params)
          end
        end
      end
    end

    def get_matchers_for(message)
      if prefix_used?(message)
        @matchers.select { |matcher| matcher[1][:prefix] }
      else
        @matchers.select { |matcher| !matcher[1][:prefix] }
      end
    end

    def prefix_used?(message)
      message.start_with?(RubyServ.config.rubyserv.prefix) || message =~ /^#{@nickname}(\W|_)/
    end

    def connected?
      @connected
    end
  end
end
