class RubyServ::IRC::Client < RubyServ::IRC::Base
  @clients  = []
  @base_uid = 0

  attr_reader :nickname

  def initialize(socket, options = {})
    @nickname = options[:nickname]
    @hostname = options[:hostname]
    @username = options[:username]
    @realname = options[:realname]
    @modes    = options[:modes]
    @socket   = socket

    base_uid = self.class.instance_variable_get(:@base_uid)
    base_uid = self.class.instance_variable_set(:@base_uid, base_uid + 1)
    @uid     = RubyServ.config.link.sid + 'SR' + ('%04d' % base_uid)

    send_raw(":#{RubyServ.config.link.sid} UID #{@nickname} 0 0 +#{@modes} #{@username} #{@hostname} 0 #{@uid} :#{@realname}")
  end

  def join(channel, op = false)
    send_raw(":#{@uid} JOIN #{Time.now.to_i} #{channel} +")

    mode(channel, "+o #{@nickname}") if op
  end

  def part(channel, message = 'Leaving channel')
  end

  def notice(target)
  end

  def message(target)
  end

  def quit(message = 'RubyServ shutdown')
  end

  def remove(channel, target, message = 'Removed')
  end

  def encap(target, command)
  end

  def kill(target, message = 'Killed')
  end

  def kick(channel, target, message = 'Kicked')
  end

  def mode(channel, modes)
    send_raw(":#{@uid} TMODE #{RubyServ::IRC::Channel.find(channel).ts} #{channel} #{modes}")
  end

  def whois(from)
    send_numeric(from, 311, "#{@nickname} #{@username} #{@hostname} * :#{@realname}")
    send_numeric(from, 312, "#{@nickname} #{RubyServ.config.rubyserv.hostname} :#{RubyServ.config.link.description}")
    send_numeric(from, 313, "#{@nickname} :is a Network Service")
    send_numeric(from, 318, "#{@nickname.downcase} :End of WHOIS")
  end

  def send_raw(text)
    puts ">> #{text}"

    @socket.puts "#{text}\r"
  end

  def send_numeric(target, numeric, text)
    send_raw(":#{RubyServ.config.link.sid} #{numeric} #{target} #{text}")
  end

  class << self
    def create(socket, options = {})
      client = self.new(socket, options)
      @clients << client
      client
    end
  end
end
