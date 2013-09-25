class RubyServ::Protocol::TS6 < RubyServ::Protocol
  def authenticate
    send("PASS #{RubyServ.config.link.password_send} TS 6 :#{RubyServ.config.link.sid}")
    send('CAPAB :QS ENCAP SAVE RSFNC SERVICES REMOVE')
    send("SERVER #{RubyServ.config.rubyserv.hostname} 0 :#{RubyServ.config.link.description}")
  end
end
