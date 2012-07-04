module Alula
  class CommonLogger
    # Common Log Format: http://httpd.apache.org/docs/1.3/logs.html#common
    # lilith.local - - [07/Aug/2006 23:58:02] "GET / HTTP/1.1" 500 -
    #             %{%s - %s [%s] "%s %s%s %s" %d %s\n} %
    FORMAT = %{[%s] %s %s\n}

    def initialize(app, logger=nil)
      @app = app
      @logger = logger
    end

    def call(env)
      status, header, body = @app.call(env)
      header = Rack::Utils::HeaderHash.new(header)
      body = Rack::BodyProxy.new(body) { log(env, status, header) }
      [status, header, body]
    end

    private

    def log(env, status, header)
      logger = @logger || env['rack.errors']
      logger.write FORMAT % [
        env["REMOTE_ADDR"],
        env["REQUEST_METHOD"],
        Rack::Utils.unescape(env["PATH_INFO"])]
    end
  end
end
