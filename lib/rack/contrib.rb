require 'rack'
module Rack
  module Contrib
    def self.release
      "0.4"
    end
  end

  autoload :MailExceptions, "rack/mailexceptions"
  autoload :Sendfile, "rack/sendfile"
end
