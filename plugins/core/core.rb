module Core
  include RubyServ::Plugin

  configure do |config|
    config.nickname = RubyServ.config.rubyserv.nickname
  end

  match(/plugins/) do |m|
    if is_oper?(m)
      m.client.notice(m.user.nickname, 'Loaded plugins:')

      RubyServ::PLUGINS.each_with_index do |plugin, index|
        m.client.notice(m.user.nickname, "#{index}: #{plugin} - nick: #{plugin.client.nickname}")
      end
    end
  end

  match(/quit/) do |m|
    if is_oper?(m)
      m.client.notice(m.user.nickname, 'Shutting down...')

      RubyServ::PLUGINS.each { |plugin| plugin.client.quit }
      RubyServ::Plugin.protocol.send_raw("SQUIT :#{RubyServ.config.link.hostname}")

      system("kill -9 #{Process.pid}")
    end
  end

  match(/load (\S+)/) do |m, plugin|
    RubyServ::Plugin.load_plugin(plugin, m.user.nickname) if is_oper?(m)
  end

  match(/unload (\S+)/) do |m, plugin|
    RubyServ::Plugin.unload_plugin(plugin, m.user.nickname) if is_oper?(m)
  end

  match(/reload (\S+)/) do |m, plugin|
    RubyServ::Plugin.reload_plugin(plugin, m.user.nickname) if is_oper?(m)
  end

  match(/join (\S+) (\S+)/) do |m, plugin, channel|
    m.Client.find_by_nickname(plugin).join(channel) if is_oper?(m)
  end

  match(/part (\S+) (\S+)/) do |m, plugin, channel|
    m.Client.find_by_nickname(plugin).part(channel) if is_oper?(m)
  end

  def is_oper?(m)
    m.user.oper?
  end
end
