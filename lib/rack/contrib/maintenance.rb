module Rack
  
  ##
  # Rack middleware to serve simple maintenance page
  #
  # By default middleware will look into current working directory
  # for file with filename ".maintenance"
  # Request will be passed next if no file found.
  # 
  # Simpliest example:
  #
  #   use Rack::Maintenance
  #
  # Set custom directory:
  #
  #   use Rack::Maintenance, '/path/to/dir'
  #
  # Customize default maintenance prompt:
  #
  #   use Rack::Maintenance do
  #     "We're doing some stuff. Come back later."
  #   end
  #
  # If you want to use timestamps in your prompt just put a valid time string
  # into your .maintenance file:
  #
  #   File.open('.maintenance', 'w') { |f| f.write(Time.now + 3600) }
  #
  # and then use it in your prompt:
  #
  #   use Rack::Maintenance do |t|
  #     "We're doing some stuff since #{t[:since} will be done at #{t[:until]}."
  #   end
  #
  
  class Maintenance
    File = ::File
    
    def initialize(app, dir=nil, &block)
      @app = app
      @block = block
      @dir = dir || File.dirname(__FILE__)
      @file = File.join(File.expand_path(@dir), '.maintenance')
    end
    
    def call(env)
      if File.exists?(@file)
        body = @block.nil? ? default_prompt(time_info) : @block.call(time_info)
        res = Response.new
        res.write(body)
        res.finish
      else
        @app.call(env)
      end
    end
    
    private
    
    def time_info
      t_since, t_until = [nil, nil]
      File.open(@file) do |f|
        t_since = f.mtime
        t_until = Time.parse(f.gets) rescue nil
        t_until = nil if t_until.kind_of?(Time) && t_until < Time.now
      end
      {:since => t_since, :until => t_until}
    end
    
    def default_prompt(t)
      if t[:until].nil? # no idea when do we end
        msg = "We're doing stuff on our servers and will be back shortly.<br/><br/>"
        msg << "<small>started: #{t[:since]}</small>"
      else
        msg = "We'll be back online on <b>#{t[:until]}</b>"
      end
      "<center><br/><br/><h1>Maintenance.</h1><p>#{msg}</p></center>"
    end
  end
end