module WEBrick
  class HTTPServer < ::WEBrick::GenericServer
    def initialize(config={}, default=Config::HTTP)
      super(config, default)
      @http_version = HTTPVersion::convert(@config[:HTTPVersion])

      @mount_tab = MountTable.new
      if @config[:DocumentRoot]
        mount("/", HTTPServlet::FileHandler, @config[:DocumentRoot],
              @config[:DocumentRootOptions])
      end

      unless @config[:AccessLog]
        @config[:AccessLog] = [
          [ RubyServ::Logger, AccessLog::COMMON_LOG_FORMAT ],
          [ RubyServ::Logger, AccessLog::REFERER_LOG_FORMAT ]
        ]
      end

      @virtual_hosts = Array.new
    end
  end
end
