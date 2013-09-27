class RubyServ::IRC::Channel
  include RubyServ::IRC::Helper

  attr_accessor :modes, :user_list, :ts
  attr_reader   :sid, :name

  @channels = []
  @statuses = [OWNER, ADMIN, OP, HALFOP, VOICE]

  def initialize(options = {})
    # TODO: Update modes, user_list, and ts when changes are made to
    # both of them
    self.modes     = options[:modes].sub('+', '')
    self.user_list = options[:users].split
    self.ts        = options[:ts]

    @sid  = options[:sid]
    @name = options[:name]
  end

  def users
    clean = user_list.map do |user|
      @statuses.each { |status| user.sub(status[:symbol], '') }
    end

    clean.each { |user| RubyServ::IRC::User.find(user) }
  end

  def destroy
    channels = self.class.instance_variable_get(:@channels)
    channels.delete_if { |channel| channel == self }
  end

  [OWNER, ADMIN, OP, HALFOP, VOICE].each do |status|
    define_method("#{status[:name]}s") do
      users.select { |user| user.start_with?(status[:symbol]) }
    end
  end

  class << self
    def create(options = {})
      @channels << self.new(options)
    end

    def all
      @channels
    end

    def find(id)
      @channels.find { |channel| channel.name == id }
    end
  end
end
