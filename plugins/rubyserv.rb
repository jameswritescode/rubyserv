class Core
  include RubyServ::Plugin

  configure do |config|
    config.nickname = RubyServ.config.rubyserv.nickname
    config.realname = RubyServ.config.rubyserv.realname
    config.hostname = RubyServ.config.rubyserv.hostname
    config.username = RubyServ.config.rubyserv.username
  end

  match(/hello/) do |m|
    puts 'someone said hello!'
  end

  match(/say (.*)/) do |m, message|
    puts "#{message}"
  end
end
