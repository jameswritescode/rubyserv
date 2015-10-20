module Core
  include RubyServ::Plugin

  configure do |config|
    config.nickname = RubyServ.config.rubyserv.nickname
  end

  before { |m| m.user.is_oper? }

  match(/plugins/, method: :plugins)
  match(/quit/, method: :quit)
  match(/load (\S+)/, method: :load)
  match(/unload (\S+)/, method: :unload)
  match(/reload (\S+)/, method: :reload)
  match(/join (\S+) (\S+)/, method: :join)
  match(/part (\S+) (\S+)/, method: :part)

  def plugins(m)
    m.client.notice(m.user.nickname, 'Loaded plugins:')

    RubyServ::PLUGINS.each_with_index do |plugin, index|
      m.client.notice(m.user.nickname, "#{index}: #{plugin} - nick: #{plugin.client.nickname}")
    end
  end

  def quit(m)
    m.client.notice(m.user.nickname, 'Shutting down...')

    RubyServ::PLUGINS.each { |plugin| plugin.client.quit }
    RubyServ::Plugin.protocol.send_raw("SQUIT :#{RubyServ.config.link.hostname}")

    system("kill -9 #{Process.pid}")
  end

  def load(m, plugin)
    RubyServ::Plugin.load_plugin(plugin, m.user.nickname)
  end

  def unload(m, plugin)
    RubyServ::Plugin.unload_plugin(plugin, m.user.nickname)
  end

  def reload(m, plugin)
    RubyServ::Plugin.reload_plugin(plugin, m.user.nickname)
  end

  def join(m, plugin, channel)
    m.Client.find_by_nickname(plugin).join(channel)
  end

  def part(m, plugin, channel)
    m.Client.find_by_nickname(plugin).part(channel)
  end
end
