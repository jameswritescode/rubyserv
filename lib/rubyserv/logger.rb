class RubyServ::Logger
  attr_accessor :channel

  @output = $stderr

  class << self
    def <<(messages)
      log(messages, :web)
    end

    def log(messages, event = :debug)
      Array(messages).each do |message|
        message = format_general(message)
        message = format_message(message, event)

        next if message.nil?

        log_file("#{message}\n")
        @output.puts message
      end
    end

    def log_file(message)
      File.open("log/rubyserv-#{Time.now.strftime('%m-%d-%y')}.log", 'a') { |f| f.write(message) }
    end

    def exception(e)
      log(e.message, :exception)
      log($!.backtrace, :exception)
    end

    def format_exception(message)
      "!! #{message}".red
    end

    def format_general(message)
      message
    end

    def format_message(message, level)
      send("format_#{level}", message)
    end

    [:error, :debug, :fatal, :info, :warn, :incoming, :outgoing, :web].each do |type|
      define_method type do |message|
        log(message, type)
      end

      next if [:fatal, :incoming, :outgoing, :info, :warn, :web].include?(type)

      define_method "format_#{type}" do |message|
        message
      end
    end

    def format_web(message)
      "WEB: #{message}".strip.magenta
    end

    def format_info(message)
      "INFO: #{message}".green
    end

    def format_incoming(message)
      ">> #{message}".strip.blue
    end

    def format_outgoing(message)
      "<< #{message}".cyan
    end

    def format_warn(message)
      "WARN: #{message}".yellow
    end

    def format_fatal(message)
      "FATAL: #{message}".red
    end
  end
end
