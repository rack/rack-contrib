module Rack
  class AB
    
    def initialize(app, options={})      
      @app = app
      @cookie_name = options[:cookie_name] || 'rack_ab'
      @possible_values = options[:possible_values] || ['a','b']
      @cookie_params = options[:cookie_params] || {}
    end

    def call(env)
      
      status, headers, body = @app.call(env)
      
      req = Request.new(env)
      
      if req.cookies[@cookie_name].nil?
        
        value = @possible_values[rand(@possible_values.length)]
        @cookie_params[:value] = value
        
        resp = Rack::Response.new(body, status, headers)
        resp.set_cookie(@cookie_name, @cookie_params)
        resp.finish
        
      else
        [status, headers, body]
      end
      
    end
  end
end