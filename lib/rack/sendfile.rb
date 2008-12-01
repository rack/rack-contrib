require 'rack/file'

module Rack
  class File #:nodoc:
    alias :to_file :path
  end

  # = Sendfile
  #
  # The Sendfile middleware intercepts responses whose body is being
  # served from a file and replaces it with a server specific X-Sendfile
  # header.
  #
  # When the response body responds to +to_file+ and the request includes
  # an X-Sendfile-Type header.
  #
  # === Nginx
  #
  # Nginx supports the X-Accel-Redirect header.
  #
  #   location /files/ {
  #     internal;
  #     alias /var/www/;
  #   }
  #
  #   location / {
  #     proxy_redirect     false;
  #
  #     proxy_set_header   Host                $host;
  #     proxy_set_header   X-Real-IP           $remote_addr;
  #     proxy_set_header   X-Forwarded-For     $proxy_add_x_forwarded_for;
  #
  #     proxy_set_header   X-Sendfile-Type     X-Accel-Redirect
  #     proxy_set_header   X-Accel-Mapping     /files/=/var/www/;
  #
  #     proxy_pass         http://127.0.0.1:8080/;
  #   }
  #
  # http://wiki.codemongers.com/NginxXSendfile
  #
  # === lighttpd
  #
  # Lighttpd has supported some variation of the X-Sendfile header for some
  # time. The following example
  #
  #   $HTTP["host"] == "example.com" {
  #      proxy-core.protocol = "http"
  #      proxy-core.balancer = "round-robin"
  #      proxy-core.backends = (
  #        "127.0.0.1:8000",
  #        "127.0.0.1:8001",
  #        ...
  #      )
  #
  #      proxy-core.allow-x-sendfile = "enable"
  #      proxy-core.rewrite-request = (
  #        "X-Sendfile-Type" => (".*" => "X-Sendfile")
  #      )
  #    }
  #
  # http://redmine.lighttpd.net/wiki/lighttpd/Docs:ModProxyCore
  #
  # === Apache
  #
  #   XSendFile on
  #
  # http://tn123.ath.cx/mod_xsendfile/

  class Sendfile
    F = ::File

    def initialize(app, variation=nil)
      @app = app
      @variation = variation
    end

    def call(env)
      status, headers, body = @app.call(env)
      if body.respond_to?(:to_file)
        case type = variation(env)
        when 'X-Accel-Redirect'
          file = F.expand_path(body.to_file)
          if url = map_accel_path(env, file)
            headers[type] = url
            body = []
          else
            env['rack.errors'] << "X-Accel-Mapping header missing"
          end
        when 'X-Sendfile', 'X-Lighttpd-Send-File'
          file = F.expand_path(body.to_file)
          headers[type] = file
          body = []
        when '', nil
        else
          env['rack.errors'] << "Unknown x-sendfile variation: '#{variation}'.\n"
        end
      end
      [status, headers, body]
    end

  private
    def variation(env)
      @variation ||
        env['sendfile.type'] ||
        env['HTTP_X_SENDFILE_TYPE']
    end

    def map_accel_path(env, file)
      if mapping = env['HTTP_X_ACCEL_MAPPING']
        internal, external = mapping.split('=', 2).map{ |p| p.strip }
        file.sub(/^#{internal}/i, external)
      end
    end
  end
end
