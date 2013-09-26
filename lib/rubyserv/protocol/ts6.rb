class RubyServ::Protocol::TS6 < RubyServ::Protocol
  def authenticate
    send("PASS #{RubyServ.config.link.password_send} TS 6 :#{RubyServ.config.link.sid}")
    send('CAPAB :QS ENCAP SAVE RSFNC SERVICES REMOVE')
    send("SERVER #{RubyServ.config.rubyserv.hostname} 0 :#{RubyServ.config.link.description}")
  end

  # PASS somepass TS 6 :42A
  def verify_authentication(input)
    if input =~ /^PASS (\S+) TS 6 :(\S{3})/
      if $1 != RubyServ.config.link.password_receive
        puts ">> #{$1} does not match the receive password configured #{RubyServ.config.link.password_receive}"
        exit
      end
    end
  end

  # PING :irc.domain.tld
  # :services.int PING services.int :rubyserv.int
  def pong(input)
    if input =~ /^PING :(.*)$/
      send("PONG: #{$1}")
    elsif input =~ /^:(\S+) PING (\S+) :(.*)$/
      send(":#{$3} PONG #{$3} :#{$1}")
    end
  end

  # SERVER irc.domain.tld 1 :Server description
  # :irc.domain.tld SERVER services.int 2 :Atheme IRC Services
  # SQUIT services.int :Remote host closed the connection
  def handle_server(input)
    if input =~ /^(\S+ )?SERVER (\S+) (\d+) :(.*)/
      RubyServ::IRC::Server.create(
        name:        $2,
        sid:         $3,
        description: $4
      )
    elsif input =~ /^SQUIT (\S+) :(.*)$/
      RubyServ::IRC::Server.find($1, :name).each { |server| server.destroy }
    end
  end

  # :00A UID HelpServ 2 1373344541 +Sio HelpServ services.int 0 00AAAAAAG :Help Services
  # :42AAAAA7B QUIT :Quit: My MacBook Pro has gone to sleep. ZZZzzz
  # :newton_ MODE newton_ :-R
  # :42AAAAAAB NICK newton_ :1380142555
  # :00A ENCAP * CHGHOST 42AAAAAAB :testing
  def handle_user(input)
    if input =~ /^:(\w{3}) UID (\S+) (\d+) (\d+) (\S+) (\S+) (\S+) (\S+) (\S+) :(.*)$/
      RubyServ::IRC::User.create(
        _1:       $1,
        nickname: $2,
        sid:      $3,
        _2:       $4,
        modes:    $5,
        username: $6,
        hostname: $7,
        _3:       $8,
        uid:      $9,
        realname: $10
      )
    elsif input =~ /^:(\S+) QUIT :(.*)$/
      RubyServ::IRC::User.find($1).first.destroy
    elsif input =~ /^:(\S+) NICK (\S+) :(.*)$/
      RubyServ::IRC::User.find($1).nickname = $2
    elsif input =~ /^:(\S+) MODE (\S+) :(.*)$/
      nick, mode = $2, $3
      modes = RubyServ::IRC::User.find(nick, :nickname).modes
      modes += mode.sub('+', '') if mode.start_with?('+')
      modes = modes.sub(mode.sub('-', ''), '') if mode.start_with?('-')

      RubyServ::IRC::User.find(nick, :nickname).modes = modes
    elsif input =~ /^(\S+) ENCAP \* CHGHOST (\S+) :(.*)$/
      RubyServ::IRC::User.find($2).hostname = $3
    end
  end

  # :42A SJOIN 1367622278 #channel +nrt :+42AAAAAYS @00AAAAAAC 42AAAAAAB
  def handle_channel(input)
    if input =~ /^:(\w{3}) SJOIN (\S+) (\S+) (\S+) :(.*)$/ # split $5 into array?
    end
  end
end
