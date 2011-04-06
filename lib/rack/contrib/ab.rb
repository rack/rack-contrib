module Rack
  class AB
    
    def initialize(app, values=['a', 'b'], name='rack_ab', expiration=nil, path='/')
      @app = app
      @name = name
      @values = values
      @expiration = expiration
      @path = path
    end

    def call(env)
      
      status, headers, body = @app.call(env)
      
      req = Request.new(env)
      
      if req.cookies[@name].nil?
        
        value = @values[rand(@values.length)]
        params = {:value => value, :path => @path, :expires => @expiration}
        
        resp = Rack::Response.new(body, status, headers)
        resp.set_cookie(@name, params)
        resp.finish
        
      else
        [status, headers, body]
      end
      
    end
  end
end