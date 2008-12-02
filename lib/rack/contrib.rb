require 'rack'
module Rack
  module Contrib
    def self.release
      "0.4"
    end
  end
  
  autoload :ContentLength,              "rack/content_length"
  autoload :ETag,                       "rack/etag"
  autoload :MailExceptions,             "rack/mailexceptions"
  autoload :Sendfile,                   "rack/sendfile"
  autoload :JSONP,                      "rack/jsonp"
  autoload :PostBodyContentTypeParser,  "rack/post_body_content_type_parser"
end
