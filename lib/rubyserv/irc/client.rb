class RubyServ::IRC::Client
  def initialize(options = {})
    @nickname = options[:nickname]
    @hostname = options[:hostname]
    @username = options[:username]
    @realname = options[:realname]
    @modes    = options[:modes]
  end

  def join(channel)
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
  end
end
