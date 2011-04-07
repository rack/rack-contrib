module Rack
  class AB
    
    def initialize(app, options={})   
      @app = app
      @cookie_name = options[:cookie_name] || 'rack_ab'
      @bucket_names = options[:bucket_names] || ['a', 'b']
      @cookie_params = options[:cookie_params] || {}
    end

    def split(blocks)
      bucket_name = req.cookies[@cookie_name]
      blocks[bucket_name].call(bucket_name)
    end
    
    def call(env)
      
      status, headers, body = @app.call(env)
      
      req = Request.new(env)
      
      if req.cookies[@cookie_name].nil?
        
        bucket_name = @bucket_names[rand(@bucket_names.length)]
        @cookie_params[:value] = bucket_name
        
        resp = Rack::Response.new(body, status, headers)
        resp.set_cookie(@cookie_name, @cookie_params)
        resp.finish
        
      else
        [status, headers, body]
      end
      
    end
  end
end