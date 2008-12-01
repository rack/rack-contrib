require 'digest/md5'

module Rack
  # Automatically sets the ETag header on all String bodies
  class ETag
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)

      if !headers.has_key?('ETag') && body.is_a?(String)
        headers['ETag'] = %("#{Digest::MD5.hexdigest(body)}")
      end

      [status, headers, body]
    end
  end
end
