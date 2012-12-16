module Rack
  class EnforceValidEncoding

    def initialize app
      @app = app
    end

    def call env
      full_path = (env.fetch('PATH_INFO', '') + env.fetch('QUERY_STRING', ''))
      if full_path.valid_encoding? && Rack::Utils.unescape(full_path).valid_encoding?
        @app.call env
      else
        [400, {'Content-Type'=>'text/plain'}, ['Bad Request']]
      end
    end
  end
end
