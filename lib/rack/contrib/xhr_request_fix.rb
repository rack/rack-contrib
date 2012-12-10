# This piece of middleware is a workaround for a problem existing in Firefox
# If an XMLHttpRequest request (request.xhr? == true) gets redirected, FF doesn't forward the
# non standard headers including XmlHttpRequest.
# This code, sets an extra url parameter in this case and manually adds the header if
# it encounters this parameter.
#
# @see: https://bugzilla.mozilla.org/show_bug.cgi?id=553888
module Rack
  class XhrRequestFix

    def initialize(app, xhr_query_string = '_xhr')
      @app = app
      @xhr_query_string = xhr_query_string
    end

    def call(env)
      if env["QUERY_STRING"].to_s =~ /#{@xhr_query_string}/
        env["HTTP_X_REQUESTED_WITH"] ||= "XMLHttpRequest"
      end
      status, headers, body = @app.call(env)
      if [301, 302, 303, 307].include?(status) && env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest" && headers['Location']
        headers["Location"] = add_xhr_to_location(headers['Location'])
      end
      [status, headers, body]
    end

    def add_xhr_to_location(location)
      [location, @xhr_query_string].join(location.include?("?") ? '&' : '?')
    end

  end
end
