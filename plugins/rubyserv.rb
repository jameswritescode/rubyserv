module Core
  include RubyServ::Plugin

  configure do |config|
    config.nickname = RubyServ.config.rubyserv.nickname
    config.prefix   = '.'
  end

  match(/plugins/) do |m|
    if is_oper?(m)
      m.client.notice(m.user.nickname, 'Loaded plugins:')

      RubyServ::PLUGINS.each do |plugin|
        m.client.notice(m.user.nickname, "#{id}: #{plugin} - nick: #{plugin.client.nickname}")
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

  match(/^load (\S+)/) do |m, plugin|
    RubyServ::Plugin.load(plugin, m.user.nickname) if is_oper?(m)
  end

  match(/unload (\S+)/) do |m, plugin|
    RubyServ::Plugin.unload(plugin, m.user.nickname) if is_oper?(m)
  end

  match(/reload (\S+)/) do |m, plugin|
    RubyServ::Plugin.reload(plugin, m.user.nickname) if is_oper?(m)
  end

  def is_oper?(m)
    m.user.oper? ? true : false
  end
end
