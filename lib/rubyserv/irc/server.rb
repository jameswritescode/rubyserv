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

    servers = self.class.instance_variable_get(:@servers)
    servers.delete_if { |server| server == self }
  end

  def users
    RubyServ::IRC::User.all.select { |user| user.server == self }
  end

  class << self
    def create(options = {})
      @servers << self.new(options)
    end

    def find(id)
      @servers.find { |server| server.sid == id }
    end
  end
end
