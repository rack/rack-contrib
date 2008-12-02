require 'rack'
module Rack
  module Contrib
    def self.release
      "0.4"
    end
  end
  
  autoload :ContentLength,              "rack/content_length"
  autoload :ETag,                       "rack/etag"
  autoload :JSONP,                      "rack/jsonp"
  autoload :MailExceptions,             "rack/mailexceptions"
  autoload :PostBodyContentTypeParser,  "rack/post_body_content_type_parser"
  autoload :Sendfile,                   "rack/sendfile"
end
