module Rack
  
  # The Rack::AB middleware splits users into buckets by selecting randomly from
  # a collection of bucket names, setting this value in a cookie, and passing this
  # value into the app via the env object.
  #
  # Example
  #
  # use Rack::AB, 
  #   :cookie_name => 'new_cookie_name',
  #   :bucket_names => [1,2,3]
  #
  # creates three buckets, 1, 2, and 3, randomly assigning each bucket name to a user, and
  # storing the bucket name in a cookie called 'new_cookie_name', e.g., new_cookie_name=1
  # 
  # Usage
  #
  # 1) Use Rack::AB middleware via 'use' directive
  # 2) Set options as desired
  # 3) Check bucket value inside Rack app via the 'rack.ab.bucket_name' member of the 
  #    env object.
  # 4) Use this bucket name to split your traffic, eg if 'a' == env['rack.ab.bucket_name']:
  #    ...; elsif 'b' == env['rack.ab.bucket_name']: ... end
  #    
  
  class AB
    
    def initialize(app, options={})   
      @app = app
      
      # Name of cookie for storing bucket name
      @cookie_name = options[:cookie_name] || 'rack_ab'
      
      # Collection of bucket names to pick randomly from
      @bucket_names = options[:bucket_names] || ['a', 'b']
      
      # Params to pass into Rack::Response::set_cookie
      # http://rack.rubyforge.org/doc/classes/Rack/Response.src/M000179.html
      @cookie_params = options[:cookie_params] || {}
      
    end
    
    def call(env)
      
      req = Request.new(env)
      
      # If user hasn't been assigned a bucket
      if req.cookies[@cookie_name].nil?
        
        bucket_name = @bucket_names[rand(@bucket_names.length)]
        
        # Add bucket name to env so app can split traffic internally
        env["rack.ab.bucket_name"] = bucket_name
        
        status, headers, body = @app.call(env)
        
        resp = Rack::Response.new(body, status, headers)
        
        # Set cookie w/ bucket name
        @cookie_params[:value] = bucket_name
        resp.set_cookie(@cookie_name, @cookie_params)
        resp.finish
        
      else
        
        env["rack.ab.bucket_name"] = req.cookies[@cookie_name]
        
        status, headers, body = @app.call(env)
        
        [status, headers, body]
      end
      
    end
    
  end
end