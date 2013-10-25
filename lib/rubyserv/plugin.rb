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
      @matchers << [pattern, options, block]
    end

    def read(input)
      if input =~ /^:(\S+) PRIVMSG (\S+) :(.*)$/
        input = OpenStruct.new(target: $2, message: $3)

        @matchers.each do |matcher|
          if match = input.message.match(matcher.first)
            client = RubyServ::IRC::Client.find_by_nickname(@nickname).first
            params = match.captures.unshift(client)

            matcher.last.call(params)
          end
        end
      end
    end

    def connected?
      @connected
    end
  end
end
