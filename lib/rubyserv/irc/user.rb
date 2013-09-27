class RubyServ::IRC::User
  include RubyServ::IRC::Helper

  attr_accessor :nickname, :hostname, :modes, :ts
  attr_reader   :realname, :uid, :username, :sid

  @users = []

  def initialize(options = {})
    self.hostname = options[:hostname]
    self.nickname = options[:nickname]
    self.modes    = options[:modes].sub('+', '')
    self.ts       = options[:ts]

    @realname = options[:realname]
    @username = options[:username]
    @uid      = options[:uid]
    @sid      = options[:sid]
  end

  def destroy
    users = self.class.instance_variable_get(:@users)
    users.delete_if { |user| user == self }
  end

  def server
    RubyServ::IRC::Server.find(@sid)
  end

  def channels
    RubyServ::IRC::Channel.all.select { |channel| channel.users.include?(@uid) }
  end

  class << self
    def create(options = {})
      @users << self.new(options)
    end

    def all
      @users
    end

    def find(id)
      @users.find { |user| user.uid == id }
    end
  end
end
