# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/expectation_cascade'

describe "Rack::ExpectationCascade" do
  def expectation_cascade(&block)
    Rack::Lint.new(Rack::ExpectationCascade.new(&block))
  end

  specify "with no apps returns a 404 if no expectation header was set" do
    app = expectation_cascade
    env = Rack::MockRequest.env_for
    response = app.call(env)
    _(response[0]).must_equal 404
    _(env['Expect']).must_be_nil
  end

  specify "with no apps returns a 417 if expectation header was set" do
    app = expectation_cascade
    env = Rack::MockRequest.env_for('', "HTTP_EXPECT" => "100-continue")
    response = app.call(env)
    _(response[0]).must_equal 417
    _(env['HTTP_EXPECT']).must_equal('100-continue')
  end

  specify "returns first successful response" do
    app = expectation_cascade do |cascade|
      cascade << lambda { |env| [417, {"content-type" => "text/plain"}, []] }
      cascade << lambda { |env| [200, {"content-type" => "text/plain"}, ["OK"]] }
    end
    env = Rack::MockRequest.env_for
    response = app.call(env)
    _(response[0]).must_equal 200
    _(response[2].to_enum.to_a).must_equal ["OK"]
  end

  specify "expectation is set if it has not been already" do
    app = expectation_cascade do |cascade|
      cascade << lambda { |env| [200, {"content-type" => "text/plain"}, ["Expect: #{env["HTTP_EXPECT"]}"]] }
    end
    env = Rack::MockRequest.env_for
    response = app.call(env)
    _(response[0]).must_equal 200
    _(response[2].to_enum.to_a).must_equal ["Expect: 100-continue"]
  end

  specify "returns a 404 if no apps where matched and no expectation header was set" do
    app = expectation_cascade do |cascade|
      cascade << lambda { |env| [417, {"content-type" => "text/plain"}, []] }
    end
    env = Rack::MockRequest.env_for
    response = app.call(env)
    _(response[0]).must_equal 404
    _(response[2].to_enum.to_a).must_equal []
  end

  specify "returns a 417 if no apps where matched and a expectation header was set" do
    app = expectation_cascade do |cascade|
      cascade << lambda { |env| [417, {"content-type" => "text/plain"}, []] }
    end
    env = Rack::MockRequest.env_for('', "HTTP_EXPECT" => "100-continue")
    response = app.call(env)
    _(response[0]).must_equal 417
    _(response[2].to_enum.to_a).must_equal []
  end

  specify "nests expectation cascades" do
    app = expectation_cascade do |c1|
      c1 << expectation_cascade do |c2|
        c2 << lambda { |env| [417, {"content-type" => "text/plain"}, []] }
      end
      c1 << expectation_cascade do |c2|
        c2 << lambda { |env| [200, {"content-type" => "text/plain"}, ["OK"]] }
      end
    end
    env = Rack::MockRequest.env_for
    response = app.call(env)
    _(response[0]).must_equal 200
    _(response[2].to_enum.to_a).must_equal ["OK"]
  end
end
