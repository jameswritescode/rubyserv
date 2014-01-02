require File.expand_path('../lib/rubyserv', File.dirname(__FILE__))

Dir[File.expand_path('..', File.dirname(__FILE__)) + '../spec/support/**/*.rb'].each { |f| require f }

def conn_config
  OpenStruct.new(
    hostname:         'localhost',
    port:             5678,
    password_receive: 'password',
    password_send:    'password',
    sid:              '0RS',
    protocol:         'TS6',
    description:      'Ruby IRC Services',
    reconnect_delay:  5,
    ssl:              false
  )
end

def start_fakeircd_and_rubyserv
  @fakeircd = Thread.new do
    EventMachine.run do
      EventMachine.start_server 'localhost', 5678, FakeIRCd
    end
  end

  @rubyserv = Thread.new do
    RubyServ::IRC.new(conn_config, '')
  end
end

def stop_fakeircd_and_rubyserv
  @rubyserv.kill
  @fakeircd.kill
end
