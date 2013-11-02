class RubyServ::IRC::User < RubyServ::IRC::Base
  attr_accessor :nickname, :hostname, :modes, :ts, :login, :realhost, :away
  attr_reader   :realname, :uid, :username, :sid

  @users = []

  def initialize(options = {})
    self.hostname = options[:hostname]
    self.nickname = options[:nickname]
    self.modes    = options[:modes].sub('+', '')
    self.ts       = options[:ts]
    self.away     = false

    @realname = options[:realname]
    @username = options[:username]
    @uid      = options[:uid]
    @sid      = options[:sid]
  end

  def server
    RubyServ::IRC::Server.find(@sid)
  end

  def channels
    RubyServ::IRC::Channel.all.select { |channel| channel.users.include?(self) }
  end

  def oper?
    modes.include?('o')
  end

  def admin?
    modes.include?('a')
  end

  def away?
    away ? true : false
  end

  def hostmask
    "#{nickname}!#{@username}@#{hostname}"
  end

  class << self
    def find(id)
      @users.find { |user| user.uid == id }
    end
  end
end
