class RubyServ::IRC::Client < RubyServ::IRC::Base
  @clients  = []
  @base_uid = 0

  attr_accessor :nickname
  attr_reader :uid, :hostname, :username, :realname, :modes

  def initialize(socket, options = {})
    @nickname = options[:nickname]
    @hostname = options[:hostname]
    @username = options[:username]
    @realname = options[:realname]
    @modes    = options[:modes]
    @protocol = RubyServ::Protocol.new(socket)

    create_user
  end

  def user
    RubyServ::IRC::User.find_by_nickname(@nickname)
  end

  def nick=(new_nick)
    if RubyServ::IRC::User.find_by_nickname(new_nick).nil?
      @protocol.send_raw(":#{@uid} NICK #{new_nick} #{Time.now.to_i}")

      plugin          = RubyServ::PLUGINS.select { |plugin| plugin.nickname == self.nickname }.first
      plugin.nickname = new_nick
      user.nickname   = new_nick
      self.nickname   = new_nick
    else
      RubyServ::Logger.info "Nickname #{new_nick} is already taken"
    end
  end

  def join(channel, op = false)
    @protocol.send_raw(":#{@uid} JOIN #{Time.now.to_i} #{channel} +")

    mode(channel, "+o #{@nickname}") if op

    RubyServ::IRC::Channel.find(channel).join(@uid, op ? '@' : nil)
  end

  def part(channel, message = 'Leaving channel')
    @protocol.send_raw(":#{@uid} PART #{channel} :#{message}")

    RubyServ::IRC::Channel.find(channel).part(@uid)
  end

  def notice(target, message)
    @protocol.send_raw(":#{@uid} NOTICE #{target} :#{message}")
  end

  def message(target, message)
    @protocol.send_raw(":#{@uid} PRIVMSG #{target} :#{message}")
  end

  def action(target, message)
    @protocol.send_raw(":#{@uid} PRIVMSG #{target} :\x01ACTION #{message}\x01")
  end

  def quit(message = 'RubyServ shutdown')
    @protocol.send_raw(":#{@uid} QUIT :#{message}")

    RubyServ::IRC::User.find_by_nickname(@nickname).channels.each do |channel|
      channel.user_list.delete_if { |user| user.include?(@nickname) }
    end

    RubyServ::IRC::User.find(@uid).destroy
    RubyServ::IRC::Client.find(@uid).destroy
  end

  def remove(channel, target, message = 'Removed')
    # TODO
  end

  def encap(target, command)
    # TODO
  end

  def kill(target, message = 'Killed')
    # TODO
  end

  def kick(channel, target, message = 'Kicked')
    # TODO
  end

  def mode(channel, modes)
    @protocol.send_raw(":#{@uid} TMODE #{RubyServ::IRC::Channel.find(channel).ts} #{channel} #{modes}")
  end

  def whois(from)
    send_numeric(from, 311, "#{@nickname} #{@username} #{@hostname} * :#{@realname}")
    send_numeric(from, 312, "#{@nickname} #{RubyServ.config.rubyserv.hostname} :#{RubyServ.config.link.description}")
    send_numeric(from, 313, "#{@nickname} :is a Network Service")
    send_numeric(from, 318, "#{@nickname.downcase} :End of WHOIS")
  end

  class << self
    def create(socket, options = {})
      client = self.new(socket, options)
      @clients << client
      client
    end

    def find(id)
      @clients.find { |client| client.uid == id }
    end
  end

  private

  def send_numeric(target, numeric, text)
    @protocol.send_raw(":#{RubyServ.config.link.sid} #{numeric} #{target} #{text}")
  end

  def create_uid
    base_uid = self.class.instance_variable_get(:@base_uid)
    base_uid = self.class.instance_variable_set(:@base_uid, base_uid + 1)
    @uid     = RubyServ.config.link.sid + 'SR' + ('%04d' % base_uid)
  end

  def create_user
    create_uid

    @protocol.send_raw(":#{RubyServ.config.link.sid} UID #{@nickname} 0 0 +#{@modes} #{@username} #{@hostname} 0 #{@uid} :#{@realname}")

    RubyServ::IRC::User.create(
      nickname: @nickname,
      sid:      '0', # TODO
      ts:       '0', # TODO
      modes:    @modes,
      username: @username,
      hostname: @hostname,
      uid:      @uid,
      realname: @realname
    )
  end
end
