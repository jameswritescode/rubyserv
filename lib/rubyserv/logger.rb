class RubyServ::Logger
  attr_accessor :channel

  def initialize(output)
    @output = output
    @level  = :debug
  end

  def log(messages, event = :debug)
    Array(messages).each do |message|
      message = format_general(message)
      message = format_message(message, event)

      next if message.nil?

      @output.puts message
    end
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

  [:error, :debug, :fatal, :info, :warn, :incoming, :outgoing].each do |type|
    define_method type do |message|
      log(message, type)
    end

    next if [:incoming, :outgoing, :info, :warn].include?(type)

    define_method "format_#{type}" do |message|
      message
    end
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
end
