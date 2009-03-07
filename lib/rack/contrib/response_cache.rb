require 'fileutils'
require 'rack'

# Rack::ResponseCache is a Rack middleware that caches responses for successful
# GET requests with no query string to disk or any ruby object that has an
# []= method (so it works with memcached).  When caching to disk, it works similar to
# Rails' page caching, allowing you to cache dynamic pages to static files that can
# be served directly by a front end webserver.
class Rack::ResponseCache
  # The default proc used if a block is not provided to .new
  # It unescapes the PATH_INFO of the environment, and makes sure that it doesn't
  # include '..'.  If the Content-Type of the response is text/(html|css|xml),
  # return a path with the appropriate extension (.html, .css, or .xml).
  # If the path ends with a / and the Content-Type is text/html, change the basename
  # of the path to index.html.
  DEFAULT_PATH_PROC = proc do |env, res|
    path = Rack::Utils.unescape(env['PATH_INFO'])
    if !path.include?('..') and match = /text\/((?:x|ht)ml|css)/o.match(res[1]['Content-Type'])
      type = match[1]
      path = "#{path}.#{type}" unless /\.#{type}\z/.match(path)
      path = File.join(File.dirname(path), 'index.html') if type == 'html' and File.basename(path) == '.html'
      path
    end
  end

  # Initialize a new ReponseCache object with the given arguments.  Arguments:
  # * app : The next middleware in the chain.  This is always called.
  # * cache : The place to cache responses.  If a string is provided, a disk
  #   cache is used, and all cached files will use this directory as the root directory.
  #   If anything other than a string is provided, it should respond to []=, which will
  #   be called with a path string and a body value (the 3rd element of the response).
  # * &block : If provided, it is called with the environment and the response from the next middleware.
  #   It should return nil or false if the path should not be cached, and should return
  #   the pathname to use as a string if the result should be cached.
  #   If not provided, the DEFAULT_PATH_PROC is used.
  def initialize(app, cache, &block)
    @app = app
    @cache = cache
    @path_proc = block || DEFAULT_PATH_PROC
  end

  # Call the next middleware with the environment.  If the request was successful (response status 200),
  # was a GET request, and had an empty query string, call the block set up in initialize to get the path.
  # If the cache is a string, create any necessary middle directories, and cache the file in the appropriate
  # subdirectory of cache.  Otherwise, cache the body of the reponse as the value with the path as the key.
  def call(env)
    res = @app.call(env)
    if env['REQUEST_METHOD'] == 'GET' and env['QUERY_STRING'] == '' and res[0] == 200 and path = @path_proc.call(env, res)
      if @cache.is_a?(String)
        path = File.join(@cache, path) if @cache
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, 'wb'){|f| res[2].each{|c| f.write(c)}}
      else
        @cache[path] = res[2]
      end
    end
    res
  end
end
