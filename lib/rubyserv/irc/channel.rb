class RubyServ::IRC::Channel < RubyServ::IRC::Base
  attr_accessor :modes, :user_list, :ts
  attr_reader   :sid, :name

  @channels = []
  STATUSES = [RubyServ::OWNER, RubyServ::ADMIN, RubyServ::OP, RubyServ::HALFOP, RubyServ::VOICE]

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
      STATUSES.each { |status| user.sub!(status[:symbol], '') }

      user
    end

    clean.map { |user| RubyServ::IRC::User.find(user) }
  end

  STATUSES.each do |status|
    define_method("#{status[:name]}s") do
      users.select { |user| user.start_with?(status[:symbol]) }
    end
  end

  class << self
    def create(options = {})
      @channels << self.new(options)
    end

    def find(id)
      @channels.find { |channel| channel.name == id }
    end
  end
end
