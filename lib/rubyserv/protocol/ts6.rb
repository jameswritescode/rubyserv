class RubyServ::Protocol::TS6 < RubyServ::Protocol
  def handle_incoming(input)
    verify_authentication(input)
    handle_errors(input)
    handle_server(input)
    handle_user(input)
    handle_channel(input)
    handle_ping(input)
    handle_whois(input)
  end

  def authenticate
    send_raw("PASS #{RubyServ.config.link.password_send} TS 6 :#{RubyServ.config.link.sid}")
    send_raw('CAPAB :QS ENCAP SAVE RSFNC SERVICES REMOVE')
    send_raw("SERVER #{RubyServ.config.rubyserv.hostname} 0 :#{RubyServ.config.link.description}")
  end

  # ERROR :Closing Link: 127.0.0.1 (Invalid servername.)
  def handle_errors(input)
    if input =~ /^ERROR :(.*): (.*)$/
      if $1 == 'Closing Link'
        RubyServ::Logger.fatal("Error encountered: #{$1} #{$2} - quitting")
        exit
      end
    end
  end

  # PASS somepass TS 6 :42A
  def verify_authentication(input)
    if input =~ /^PASS (\S+) TS 6 :(\S{3})/
      if $1 != RubyServ.config.link.password_receive
        RubyServ::Logger.fatal("#{$1} does not match the receive password configured #{RubyServ.config.link.password_receive}")
        exit
      end
    end
  end

  # PING :irc.domain.tld
  # :services.int PING services.int :rubyserv.int
  def handle_ping(input)
    if input =~ /^PING :(.*)$/
      send_raw("PONG :#{$1}")

      RubyServ::IRC.connected = true unless RubyServ::IRC.connected?
    elsif input =~ /^:(\S+) PING (\S+) :(.*)$/
      send_raw(":#{$3} PONG #{$3} :#{$1}")
    end
  end

  # SERVER irc.domain.tld 1 :Server description
  # :irc.domain.tld SERVER services.int 2 :Atheme IRC Services
  # SQUIT services.int :Remote host closed the connection
  # :42A SID services.int 2 00A :Atheme IRC Services
  def handle_server(input)
    if input =~ /^(\S+ )?SERVER (\S+) (\d+) :(.*)/
      send_svinfo if $1.nil? && !RubyServ::IRC.connected?

      RubyServ::IRC::Server.create(
        _1:          $1,
        name:        $2,
        sid:         $3,
        description: $4
      )
    elsif input =~ /^:(\S{3}) SID (\S+) (\d) (\S{3}) :(.*)$/
      RubyServ::IRC::Server.create(
        _1:          $1,
        name:        $2,
        _2:          $3,
        sid:         $4,
        description: $5
      )
    elsif input =~ /^SQUIT (\S+) :(.*)$/
      if $1 =~ /(\S{3})/
        RubyServ::IRC::Server.find_by_sid($1)
      else
        RubyServ::IRC::Server.find_by_name($1).destroy
      end
    end
  end

  def send_svinfo
    send_raw("SVINFO 6 6 0 :#{Time.now.to_i}")
  end

  # :00A UID HelpServ 2 1373344541 +Sio HelpServ services.int 0 00AAAAAAG :Help Services
  # :42AAAAA7B QUIT :Quit: My MacBook Pro has gone to sleep. ZZZzzz
  # :newton_ MODE newton_ :-R
  # :42AAAAAAB NICK newton_ :1380142555
  # :00A ENCAP * CHGHOST 42AAAAAAB :testing
  # :42AAAAAYS ENCAP * REALHOST 127.0.0.1.host.name
  # :42AAAAAYS ENCAP * LOGIN howell
  # :42AAAAAAB AWAY :detached from screen
  # :42AAAAAAB AWAY
  def handle_user(input)
    if input =~ /^:(\w{3}) UID (\S+) (\d+) (\d+) (\S+) (\S+) (\S+) (\S+) (\S+) :(.*)$/
      RubyServ::IRC::User.create(
        _1:       $1,
        nickname: $2,
        sid:      $3,
        ts:       $4,
        modes:    $5,
        username: $6,
        hostname: $7,
        _3:       $8,
        uid:      $9,
        realname: $10
      )
    elsif input =~ /^:(\S+) QUIT :(.*)$/
      RubyServ::IRC::User.find($1).quit
    elsif input =~ /^:(\S+) NICK (\S+) :(.*)$/
      RubyServ::IRC::User.find($1).update(nickname: $2, ts: $3)
    elsif input =~ /^:(\S+) MODE (\S+) :(.*)$/
      nick, mode = $2, $3
      user       = RubyServ::IRC::User.find_by_nickname(nick)
      modes      = user.modes
      modes     += mode.sub('+', '') if mode.start_with?('+')
      modes      = modes.sub(mode.sub('-', ''), '') if mode.start_with?('-')
      user.modes = modes
    elsif input =~ /^(\S+) ENCAP \* CHGHOST (\S+) :(.*)$/
      RubyServ::IRC::User.find($2).hostname = $3
    elsif input =~ /^:(\S+) ENCAP \* REALHOST (\S+)$/
      RubyServ::IRC::User.find($1).realhost = $2
    elsif input =~ /^:(\S+) ENCAP \* LOGIN (\S+)$/
      RubyServ::IRC::User.find($1).login = $2
    elsif input =~ /^:(\S+) AWAY :(.*)$/
      RubyServ::IRC::User.find($1).away = $2
    elsif input =~ /^:(\S+) AWAY$/
      RubyServ::IRC::User.find($1).away = nil
    end
  end

  # :42A SJOIN 1367622278 #channel +nrt :+42AAAAAYS @00AAAAAAC 42AAAAAAB
  # :42AAAAAAB PART #test
  # :42AAAAAAB JOIN 1380336072 #test +
  # TODO :42AAAAAAB TMODE 1383172359 #honk -L+m
  # TODO :42AAAAAAB TMODE 1383172638 #honk -o 42AAAAAAB
  def handle_channel(input)
    if input =~ /^:(\w{3}) SJOIN (\S+) (\S+) (\S+) :(.*)$/
      RubyServ::IRC::Channel.create(
        sid:   $1,
        ts:    $2,
        name:  $3,
        modes: $4,
        users: $5
      )
    elsif input =~ /^:(\S+) PART (\S+)$/
      channel = RubyServ::IRC::Channel.find($2)
      channel.part($1)
      channel.destroy if channel.users.count.zero?
    elsif input =~ /^:(\S+) JOIN (\d+) (\S+) \+$/
      RubyServ::IRC::Channel.find($3).join($1)
    end
  end

  # :42AAAAAAB WHOIS 0RSSR0001 :RubyServ
  def handle_whois(input)
    if input =~ /^:(\S+) WHOIS (\S+) :(.*)$/
      RubyServ::IRC::Client.find_by_uid($2).whois($1)
    end
  end
end
