module WEBrick
  class BasicLog
    def log(level, data)
      if @log && level <= @level
        data += "\n" if /\n\Z/ !~ data
        RubyServ::Logger << data
      end
    end
  end
end
