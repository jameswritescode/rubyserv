class RubyServ::IRC::Server < RubyServ::IRC::Base
  attr_reader :sid, :name, :description

  @servers = []

  def initialize(options = {})
    @sid         = options[:sid]
    @name        = options[:name]
    @description = options[:description]
  end

  def destroy
    users = RubyServ::IRC::User.find_by_sid(@sid).first
    users.each { |user| user.destroy }

    super
  end

  def users
    RubyServ::IRC::User.all.select { |user| user.server == self }
  end

  class << self
    def find(id)
      @servers.find { |server| server.sid == id }
    end
  end
end
