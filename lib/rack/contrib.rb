require 'rack'
module Rack
  module Contrib
    def self.release
      "0.4"
    end
  end

  autoload :ContentLength, "rack/content_length"
  autoload :MailExceptions, "rack/mailexceptions"
  autoload :Sendfile, "rack/sendfile"
end
