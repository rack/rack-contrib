module Rack

  # Rack middleware implementing the IETF draft: "Host Metadata for the Web"
  #
  # Usage:
  #  use Rack::HostMeta do
  #    register :uri => '/robots.txt', :rel => 'robots'
  #    register :uri => '/w3c/p3p.xml', :rel => 'privacy', :type => 'application/p3p.xml'
  #  end
  #
  # See also: http://tools.ietf.org/html/draft-nottingham-site-meta
  #
  # TODO:
  #   Accept POST operations allowing downstream services to register themselves
  #
  class HostMeta
    def initialize(app, &block)
      @app = app
      @links = []
      instance_eval(&block)
      @response = @links.join("\n")
    end

    def call(env)
      if env['PATH_INFO'] == '/host-meta'
        [200, {'Content-Type' => 'application/host-meta'}, [@response]]
      else
        @app.call(env)
      end
    end

    protected

    def register(config)
      link = "Link: <#{config[:uri]}>;"
      link += " rel=\"#{config[:rel]}\"" if config[:rel]
      link += " type=\"#{config[:type]}\"" if config[:type]
      @links << link
    end
  end
end
