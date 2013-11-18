class RubyServ::Protocol
  attr_reader :socket

  def initialize(socket)
    @socket = socket
  end

  [:handle_incoming, :authenticate].each do |name|
    define_method(name) { |input| raise "##{name} must be defined in the protocol" }
  end

  # TODO :42AAAABCJ VERSION :0RS
  # :42AAAABCJ PRIVMSG 0RSSR0001 :VERSION
  def handle_version(input)
    version = "RubyServ #{RubyServ::VERSION} (#{RubyServ.config.rubyserv.hostname} #{RubyServ::REVISION}) https://github.com/jameswritescode/rubyserv"

    if input =~ /^:(\S+) VERSION :(\S+)$/
    elsif input =~ /^:(\S+) PRIVMSG (\S+) :\x01VERSION\x01$/
      RubyServ::IRC::Client.find_by_uid($2).notice($1, "\001VERSION #{version}\001")
    end
  end

  def handle_client_commands(input)
    RubyServ::PLUGINS.each do |plugin|
      plugin.__read(input) if plugin.connected?
    end
  end

  def send_raw(text)
    RubyServ::Logger.outgoing text

    sleep(0.05)
    @socket.puts "#{text}\r"
  end
end
