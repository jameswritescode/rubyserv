module RubyServ::Protocols
  class TS6
    attr_accessor :name, :server_id

    def initialize
      self.name      = RubyServ.config.link.hostname
      self.server_id = RubyServ.config.link.sid
    end

    def on_start(link)
      self.link = link

      send("PASS #{RubyServ.config.link.password_send} TS 6 :#{RubyServ.config.link.sid}")
      send('CAPAB :QS ENCAP SAVE RSFNC SERVICES REMOVE')
      send("SERVER #{RubyServ.config.link.hostname} 0 :#{RubyServ.config.link.description}")
    end

    def on_output(line)
      send(line)
    end

    def on_close(link)
      sleep RubyServ.config.link.reconnect_delay

      system('/usr/bin/env', 'ruby', RubyServ.root.join('bin', 'rubyserv'))

      exit
    end

    def send(text)
      self.link.send(text) if self.link
    end
  end
end
