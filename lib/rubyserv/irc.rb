class RubyServ::IRC
  attr_accessor :server, :port, :connected, :buffer

  def initialize(server, port)
    self.server = server
    self.port   = port
    self.buffer = []

    start
  end

  def start
    return socket if connected

    socket = TCPSocket.new(server, port) # TODO: SSL

    if RubyServ.config['link']['ssl'] == true
      require 'openssl'

      context             = OpenSSL::SSL::SSLContext.new
      context.verify_mode = OpenSSL::SSL::VERIFY_NONE

      socket            = OpenSSL::SSL::SSLSocket.new(socket, context)
      socket.sync_close = true
      socket.connect
    end
  end

  def on_link_start(link)
    if link == self
      connected = true

      Thread.new { main_loop }

      @buffer.each { |msg| send(msg) }
    else
      socket.close if socket
      connected = false
    end
  end

  def send(text)
    if connected
      socket.puts text.chomp
    else
      buffer << text
    end
  end

  def main_loop
    while connected
      begin
        x = socket.gets

        raise 'Disconnected' if x.nil?
      rescue 'Disconnected'
        connected = false
        socket.close
        socket = nil
        buffer.clear
      end
    end
  end
end
