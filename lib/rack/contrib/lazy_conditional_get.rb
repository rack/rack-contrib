module Rack

  ##
  # This middleware is like Rack::ConditionalGet except that it does
  # not have to go down the rack stack and build the ressource to check
  # the modification date or the ETag.
  #
  # Instead it makes the assumption that only non-reading requests can 
  # potentially change the content. So it uses and caches a `global_last_modified`
  # date and updates it on requests which are not GET or HEAD.
  #
  # Basically you use it this way:
  #
  # ``` ruby
  # use Rack::LazyConditionalGet
  # ```
  #
  # Although if you have multiple instances, it is better to use something like 
  # memcached. An argument can be passed to give the cache object. By default
  # it is just a Hash. But it can take other objects, including objects which
  # respond to `:get` and `:set`. Here is how you would use it with Dalli.
  #
  # ``` Ruby
  # dalli_client = Dalli::Client.new
  # use Rack::LazyConditionalGet, dalli_client
  # ```
  #
  # By default, the middleware only delegates to Rack::ConditionalGet to avoid
  # any unwanted behaviour. You have to set a header to any ressource which you 
  # want to be cached. And it will be cached until the next "potential update" 
  # of your site.
  #
  # The header is `X-Lazy-Conditional-Get`. You have to set it to either 'yes',
  # 'true' or '1' if you want the middleware to set `Last-Modified` for you.
  #
  # Bare in mind that if you set `Last-Modified` as well, the middleware will 
  # not change it.
  #
  # Regarding the POST/PUT/DELETE... requests, they will always reset your 
  # `global_last_modified` date. But if you have one of these request and you 
  # know for sure that it does not modify the cached content, you can set the
  # `X-Lazy-Conditional-Get` on response to `skip`. This will not update the
  # `global_last_modified` date.

  class LazyConditionalGet

    KEY = 'global_last_modified'.freeze
    READ_METHODS = ['GET','HEAD']
    TRUTHINESS = ['true','yes','1']

    def self.new(*); ::Rack::ConditionalGet.new(super); end

    def initialize app, cache={}
      @app = app
      @cache = cache
      update_cache
    end

    def call env
      if reading? env and fresh? env
        return [200,{'Last-Modified'=>env['HTTP_IF_MODIFIED_SINCE']},[]]
      end
      status,headers,body = @app.call env
      update_cache unless (reading?(env) or skipping?(headers))
      headers['Last-Modified'] = cached_value if stampable? headers
      [status,headers,body]
    end

    private

    def fresh? env
      env['HTTP_IF_MODIFIED_SINCE']==cached_value
    end

    def reading? env
      READ_METHODS.include?(env['REQUEST_METHOD'])
    end

    def skipping? headers
      headers['X-Lazy-Conditional-Get']=='skip'
    end

    def stampable? headers
      headers['Last-Modified'].to_s=='' and
      TRUTHINESS.include?(headers['X-Lazy-Conditional-Get'])
    end

    def update_cache
      stamp = Time.now.httpdate
      if @cache.respond_to?(:set)
        @cache.set(KEY,stamp)
      else
        @cache[KEY] = stamp
      end
    end

    def cached_value
      @cache.respond_to?(:get) ? @cache.get(KEY) : @cache[KEY]
    end

  end

end

