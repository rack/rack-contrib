require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/lazy_conditional_get'

$lazy_conditional_get_cache = {}

describe 'Rack::LazyConditionalGet' do

  def global_last_modified
    $lazy_conditional_get_cache[Rack::LazyConditionalGet::KEY]
  end

  def set_global_last_modified val
    $lazy_conditional_get_cache[Rack::LazyConditionalGet::KEY] = val
  end

  let(:core_app) {
    lambda { |env| [200, response_headers, ['data']] }
  }

  let(:response_headers) {
    headers = {
      'Content-Type' => 'text/plain',
      'Rack-Lazy-Conditional-Get' => rack_lazy_conditional_get
    }
    if response_with_last_modified
      headers.merge!({'Last-Modified' => (Time.now-3600).httpdate})
    end
    headers
  }

  let(:response_with_last_modified) { false }

  let(:rack_lazy_conditional_get) { 'yes' }

  let(:app) {
    Rack::LazyConditionalGet.new core_app, $lazy_conditional_get_cache
  }

  let(:env) {
    Rack::MockRequest.env_for '/', request_headers
  }

  let(:request_headers) {
    headers = { 'REQUEST_METHOD' => request_method }
    if request_with_current_date
      headers.merge!({'HTTP_IF_MODIFIED_SINCE' => global_last_modified})
    end
    headers
  }

  let(:request_method) { 'GET' }

  let (:request_with_current_date) { false }

  before { @myapp = app }

  describe 'When the resource has Rack-Lazy-Conditional-Get' do

    it 'Should set right headers' do
      status, headers, body = @myapp.call(env)
      value(status).must_equal 200
      value(headers['Rack-Lazy-Conditional-Get']).must_equal 'yes'
      value(headers['Last-Modified']).must_equal global_last_modified
    end

    describe 'When the resource already has a Last-Modified header' do

      let(:response_with_last_modified) { true }

      it 'Does not update Last-Modified with the global one' do
        status, headers, body = @myapp.call(env)
        value(status).must_equal 200
        value(headers['Rack-Lazy-Conditional-Get']).must_equal 'yes'
        value(headers['Last-Modified']).wont_equal global_last_modified
      end

    end

    describe 'When loading a resource for the second time' do

      let(:core_app) { lambda { |env| raise } }
      let(:request_with_current_date) { true }

      it 'Should not render resource the second time' do
        status, headers, body = @myapp.call(env)
        value(status).must_equal 304
      end

    end

  end

  describe 'When a request is potentially changing data' do

    let(:request_method) { 'POST' }

    it 'Updates the global_last_modified' do
      set_global_last_modified (Time.now-3600).httpdate
      stamp = global_last_modified
      status, headers, body = @myapp.call(env)
      value(global_last_modified).wont_equal stamp
    end

    describe 'When the skip header is returned' do

      let(:rack_lazy_conditional_get) { 'skip' }

      it 'Does not update the global_last_modified' do
        set_global_last_modified (Time.now-3600).httpdate
        stamp = global_last_modified
        status, headers, body = @myapp.call(env)
        value(headers['Rack-Lazy-Conditional-Get']).must_equal 'skip'
        value(global_last_modified).must_equal stamp
      end

    end

  end

  describe 'When the ressource does not have Rack-Lazy-Conditional-Get' do

    let(:rack_lazy_conditional_get) { 'no' }

    it 'Should set right headers' do
      status, headers, body = @myapp.call(env)
      value(status).must_equal 200
      value(headers['Rack-Lazy-Conditional-Get']).must_equal 'no'
      value(headers['Last-Modified']).must_be :nil?
    end

  end

end

