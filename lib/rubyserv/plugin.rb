module RubyServ::Plugin
  def self.included(klass)
    RubyServ::PLUGINS << klass

    klass.send(:extend, ClassMethods)
  end

  module ClassMethods
    attr_accessor :realname, :nickname, :hostname, :username
    attr_reader   :matchers
    attr_writer   :connected, :channels

    def self.extended(klass)
      klass.instance_exec do
        @matchers  = []
        @channels  = []
        @connected = false
      end
    end

    def configure(&block)
      yield self
    end

    def channels
      schan = RubyServ.config.rubyserv.channel

      @channels << schan unless @channels.include?(schan)
      @channels
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
