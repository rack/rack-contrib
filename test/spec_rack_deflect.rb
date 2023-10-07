# frozen_string_literal: true

require 'minitest/autorun'
require 'timecop'
require 'rack/mock'
require 'rack/contrib/deflect'

describe "Rack::Deflect" do

  before do
    @app = lambda { |env| [200, { 'content-type' => 'text/plain' }, ['cookies']] }
    @mock_addr_1 = '111.111.111.111'
    @mock_addr_2 = '222.222.222.222'
    @mock_addr_3 = '333.333.333.333'
  end

  def mock_env remote_addr, path = '/'
    Rack::MockRequest.env_for path, { 'REMOTE_ADDR' => remote_addr }
  end

  def mock_deflect options = {}
    Rack::Lint.new(Rack::Deflect.new(@app, options))
  end

  specify "should allow regular requests to follow through" do
    app = mock_deflect
    status, headers, body = app.call mock_env(@mock_addr_1)
    _(status).must_equal 200
    _(body.to_enum.to_a).must_equal ['cookies']
  end

  specify "should deflect requests exceeding the request threshold" do
    log = StringIO.new
    app = mock_deflect :request_threshold => 5, :interval => 10, :block_duration => 10, :log => log
    env = mock_env @mock_addr_1

    # First 5 should be fine
    5.times do
      status, headers, body = app.call env
      _(status).must_equal 200
      if Rack.release < "3"
        _(body.to_enum.to_a).must_equal ['cookies']
      else
        _(body.to_ary).must_equal ['cookies']
      end
    end

    # Remaining requests should fail for 10 seconds
    10.times do
      status, headers, body = app.call env
      _(status).must_equal 403
      _(body.to_enum.to_a).must_equal []
    end

    # Log should reflect that we have blocked an address
    _(log.string).must_match(/^deflect\(\d+\/\d+\/\d+\): blocked 111.111.111.111\n/)
  end

  specify "should expire blocking" do
    log = StringIO.new
    app = mock_deflect :request_threshold => 5, :interval => 2, :block_duration => 2, :log => log
    env = mock_env @mock_addr_1

    # First 5 should be fine
    5.times do
      status, headers, body = app.call env
      _(status).must_equal 200
      if Rack.release < "3"
        _(body.to_enum.to_a).must_equal ['cookies']
      else
        _(body.to_ary).must_equal ['cookies']
      end
    end

    # Exceeds request threshold
    status, headers, body = app.call env
    _(status).must_equal 403
    _(body.to_enum.to_a).must_equal []

    # Move to the future so the block will expire
    Timecop.travel(Time.now + 3) do
      # Another 5 is fine now
      5.times do
        status, headers, body = app.call env
        _(status).must_equal 200
        _(body.to_enum.to_a).must_equal ['cookies']
      end
    end

    # Log should reflect block and release
    _(log.string).must_match(/deflect.*: blocked 111\.111\.111\.111\ndeflect.*: released 111\.111\.111\.111\n/)
  end

  specify "should allow whitelisting of remote addresses" do
    app = mock_deflect :whitelist => [@mock_addr_1], :request_threshold => 5, :interval => 2
    env = mock_env @mock_addr_1

    # Whitelisted addresses are always fine
    10.times do
      status, headers, body = app.call env
      _(status).must_equal 200
      if Rack.release < "3"
        _(body.to_enum.to_a).must_equal ['cookies']
      else
        _(body.to_ary).must_equal ['cookies']
      end
    end
  end

  specify "should allow blacklisting of remote addresses" do
    app = mock_deflect :blacklist => [@mock_addr_2]

    status, headers, body = app.call mock_env(@mock_addr_1)
    _(status).must_equal 200
    _(body.to_enum.to_a).must_equal ['cookies']

    status, headers, body = app.call mock_env(@mock_addr_2)
    _(status).must_equal 403
    _(body.to_enum.to_a).must_equal []
  end

end
