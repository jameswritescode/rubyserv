class RubyServ::IRC::Server
  attr_reader :sid, :name, :description

  @servers = []

  def initialize(options = {})
    @sid         = options[:sid]
    @name        = options[:name]
    @description = options[:description]
  end

  def destroy
    users = RubyServ::IRC::User.find(@sid, :sid)
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

    def all
      @servers
    end

    def find(id, method = :sid)
      @servers.select { |server| server.send(method) == id }
    end
  end
end
