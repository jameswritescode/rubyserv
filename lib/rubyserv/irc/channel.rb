class RubyServ::IRC::Channel < RubyServ::IRC::Base
  attr_accessor :modes, :user_list, :ts
  attr_reader   :sid, :name

  @channels = []
  STATUSES  = [RubyServ::OWNER, RubyServ::ADMIN, RubyServ::OP, RubyServ::HALFOP, RubyServ::VOICE]

  def initialize(options = {})
    # TODO Update modes, and ts when changes are made to them
    self.modes     = options[:modes].sub('+', '')
    self.user_list = options[:users].split
    self.ts        = options[:ts]

    @sid  = options[:sid]
    @name = options[:name]
  end

  def users
    user_list.map do |user|
      STATUSES.each { |status| user = user.sub(status[:symbol], '') }

      RubyServ::IRC::User.find(user)
    end
  end

  STATUSES.each do |status|
    define_method("#{status[:name]}s") do
      user_list.select { |user| user.start_with?(status[:symbol]) }.map do |user|
        RubyServ::IRC::User.find(user.sub(status[:symbol], ''))
      end
    end
  end

  def join(uid, mode = nil)
    self.user_list << "#{mode}#{uid}"
  end

  def part(uid)
    self.user_list.delete_if { |user| user.include?(uid) }
  end

  class << self
    def find(id)
      @channels.find { |channel| channel.name == id }
    end
  end
end
