module Rack
  #prints the environment and request for simple debugging
  class Printout
    def initialize(app)
      @app = app
    end

    def call(env)
      # See http://rack.rubyforge.org/doc/SPEC.html for details
      puts "**********\n Environment\n **************"
      puts env.inspect
      
      puts "**********\n Response\n **************"
      response = @app.call(env)
      puts response.inspect

      puts "**********\n Response contents\n **************"
      response[2].each do |chunk|
        puts chunk
      end
      puts "\n \n"
      return response
    end
  end
end
