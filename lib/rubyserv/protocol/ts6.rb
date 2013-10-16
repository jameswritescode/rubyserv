class RubyServ::Protocol::TS6 < RubyServ::Protocol
  def authenticate
    send("PASS #{RubyServ.config.link.password_send} TS 6 :#{RubyServ.config.link.sid}")
    send('CAPAB :QS ENCAP SAVE RSFNC SERVICES REMOVE')
    send("SERVER #{RubyServ.config.rubyserv.hostname} 0 :#{RubyServ.config.link.description}")
  end

  # ERROR :Closing Link: 127.0.0.1 (Invalid servername.)
  def handle_errors(input)
    if input =~ /^ERROR :(.*): .*$/
      if $1 == 'Closing Link'
        puts ">> Error encountered: #{$1} #{$2} - quitting"
        exit
      end
    end
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
  def handle_ping(input)
    if input =~ /^PING :(.*)$/
      send("PONG :#{$1}")

      RubyServ::IRC.connected = true unless RubyServ::IRC.connected?
    elsif input =~ /^:(\S+) PING (\S+) :(.*)$/
      send(":#{$3} PONG #{$3} :#{$1}")
    end
  end

  # SERVER irc.domain.tld 1 :Server description
  # :irc.domain.tld SERVER services.int 2 :Atheme IRC Services
  # SQUIT services.int :Remote host closed the connection
  # TODO :42A SID services.int 2 00A :Atheme IRC Services
  def handle_server(input)
    if input =~ /^(\S+ )?SERVER (\S+) (\d+) :(.*)/
      send_svinfo if $1.nil? && !RubyServ::IRC.connected?

      RubyServ::IRC::Server.create(
        _1:          $1,
        name:        $2,
        sid:         $3,
        description: $4
      )
    elsif input =~ /^SQUIT (\S+) :(.*)$/
      RubyServ::IRC::Server.find_by_name($1).each { |server| server.destroy }
    end
  end

  def send_svinfo
    send("SVINFO 6 6 0 :#{Time.now.to_i}")
  end

  # :00A UID HelpServ 2 1373344541 +Sio HelpServ services.int 0 00AAAAAAG :Help Services
  # :42AAAAA7B QUIT :Quit: My MacBook Pro has gone to sleep. ZZZzzz
  # :newton_ MODE newton_ :-R
  # :42AAAAAAB NICK newton_ :1380142555
  # :00A ENCAP * CHGHOST 42AAAAAAB :testing
  # TODO :42AAAAAYS ENCAP * REALHOST 127.0.0.1.host.name
  # TODO :42AAAAAYS ENCAP * LOGIN howell
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
      RubyServ::IRC::User.find($1).destroy
    elsif input =~ /^:(\S+) NICK (\S+) :(.*)$/
      user          = RubyServ::IRC::User.find($1)
      user.nickname = $2
      user.ts       = $3
    elsif input =~ /^:(\S+) MODE (\S+) :(.*)$/
      nick, mode = $2, $3
      modes = RubyServ::IRC::User.find_by_nickname(nick).first.modes
      modes += mode.sub('+', '') if mode.start_with?('+')
      modes = modes.sub(mode.sub('-', ''), '') if mode.start_with?('-')

      RubyServ::IRC::User.find_by_nickname(nick).first.modes = modes
    elsif input =~ /^(\S+) ENCAP \* CHGHOST (\S+) :(.*)$/
      RubyServ::IRC::User.find($2).hostname = $3
    end
  end

  # :42A SJOIN 1367622278 #channel +nrt :+42AAAAAYS @00AAAAAAC 42AAAAAAB
  # TODO :42AAAAAAB PART #test
  # TODO :42AAAAAAB JOIN 1380336072 #test +
  def handle_channel(input)
    if input =~ /^:(\w{3}) SJOIN (\S+) (\S+) (\S+) :(.*)$/
      RubyServ::IRC::Channel.create(
        sid:   $1,
        ts:    $2,
        name:  $3,
        modes: $4,
        users: $5
      )
    end
  end

  # :42AAAAAAB WHOIS 0RSSR0001 :RubyServ
  def handle_whois(input)
    if input =~ /^:(\S+) WHOIS (\S+) :(.*)$/
      RubyServ::IRC::Client.find_by_uid($2).first.whois($1)
    end
  end
end
