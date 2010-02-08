module Rack
  # Automatically sets the ETag header on all String bodies
  # if none is set.
  #
  # By default, uses an MD5 hash to generate the ETag.
  #
  # @param [#call] app the underlying Rack application. Required.
  # @param [Symbol] digest the digest to use. Optional. Options are [:md5, :sha1, :sha256, :sha384, :sha512].
  class ETag
    def initialize(app, digest = :md5)
      @app = app
      load_digest(digest)
      @digest_method = self.method("#{digest}_hash")
    end

    def call(env)
      status, headers, body = @app.call(env)

      if !headers.has_key?('ETag') && body.is_a?(String)
        headers['ETag'] = %("#{@digest_method.call(body)}")
      end

      [status, headers, body]
    end

    private

    def load_digest(digest)
      case digest
      when :md5
        require 'digest/md5'
      when :sha1
        require 'digest/sha1'
      when :sha256, :sha384, :sha512
        require 'digest/sha2'
      else
        raise ArgumentError.new("Digest #{digest} is not supported.")
      end
    end

    def md5_hash(body)
      Digest::MD5.hexdigest(body)
    end

    def sha1_hash(body)
      Digest::SHA1.hexdigest(body)
    end

    def sha256_hash(body)
      Digest::SHA2.hexdigest(body)
    end

    def sha384_hash(body)
      (Digest::SHA2.new(384) << body).to_s
    end

    def sha512_hash(body)
      (Digest::SHA2.new(512) << body).to_s
    end
  end
end
