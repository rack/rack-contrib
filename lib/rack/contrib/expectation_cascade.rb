module Rack
  class ExpectationCascade
    Expect = "Expect".freeze
    ContinueExpectation = "100-continue".freeze

    ExpectationFailed = [417, {"Content-Type" => "text/html"}, []].freeze
    NotFound = [404, {"Content-Type" => "text/html"}, []].freeze

    attr_reader :apps

    def initialize
      @apps = []
      yield self if block_given?
    end

    def call(env)
      set_expectation = env[Expect] != ContinueExpectation
      env[Expect] = ContinueExpectation if set_expectation
      @apps.each do |app|
        result = app.call(env)
        return result unless result[0].to_i == 417
      end
      set_expectation ? NotFound : ExpectationFailed
    ensure
      env.delete(Expect) if set_expectation
    end

    def <<(app)
      @apps << app
    end
  end
end
