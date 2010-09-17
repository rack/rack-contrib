require 'test/spec'
require 'rack/mock'

begin
  require 'tmail'
  require 'rack/contrib/mailexceptions'

  require File.dirname(__FILE__) + '/mail_settings.rb'

  class TestError < RuntimeError
  end

  def test_exception
    raise TestError, 'Suffering Succotash!'
  rescue => boom
    return boom
  end

  context 'Rack::MailExceptions' do

    setup do
      @app = lambda { |env| raise TestError, 'Why, I say' }
      @env = Rack::MockRequest.env_for("/foo",
        'FOO' => 'BAR',
        :method => 'GET',
        :input => 'THE BODY'
      )
      @smtp_settings = {
        :server         => 'example.com',
        :domain         => 'example.com',
        :port           => 500,
        :authentication => :login,
        :user_name      => 'joe',
        :password       => 'secret'
      }
    end

    specify 'yields a configuration object to the block when created' do
      called = false
      mailer =
        Rack::MailExceptions.new(@app) do |mail|
          called = true
          mail.to 'foo@example.org'
          mail.from 'bar@example.org'
          mail.subject '[ERROR] %s'
          mail.smtp @smtp_settings
        end
      called.should.be == true
    end

    specify 'generates a TMail object with configured settings' do
      mailer =
        Rack::MailExceptions.new(@app) do |mail|
          mail.to 'foo@example.org'
          mail.from 'bar@example.org'
          mail.subject '[ERROR] %s'
          mail.smtp @smtp_settings
        end

      tmail = mailer.send(:generate_mail, test_exception, @env)
      tmail.to.should.equal ['foo@example.org']
      tmail.from.should.equal ['bar@example.org']
      tmail.subject.should.equal '[ERROR] Suffering Succotash!'
      tmail.body.should.not.be.nil
      tmail.body.should.be =~ /FOO:\s+"BAR"/
      tmail.body.should.be =~ /^\s*THE BODY\s*$/
    end

    specify 'catches exceptions raised from app, sends mail, and re-raises' do
      mailer =
        Rack::MailExceptions.new(@app) do |mail|
          mail.to 'foo@example.org'
          mail.from 'bar@example.org'
          mail.subject '[ERROR] %s'
          mail.smtp @smtp_settings
        end
      lambda { mailer.call(@env) }.should.raise(TestError)
      @env['mail.sent'].should.be == true
    end

    if TEST_SMTP && ! TEST_SMTP.empty?
      specify 'sends mail' do
        mailer =
          Rack::MailExceptions.new(@app) do |mail|
            mail.config.merge! TEST_SMTP
          end
        lambda { mailer.call(@env) }.should.raise(TestError)
        @env['mail.sent'].should.be == true
      end
    else
      STDERR.puts 'WARN: Skipping SMTP tests (edit test/mail_settings.rb to enable)'
    end

    context 'for tls enabled smtp' do
      setup do
        @smtp_settings.merge!(TEST_SMTP_TLS)
        @mailer = 
          Rack::MailExceptions.new(@app) do |mail|
            mail.to TEST_SMTP_TLS.values_at(:user_name, :domain).join('@')
            mail.from 'bar@example.org'
            mail.subject '[ERROR] %s'
            mail.smtp @smtp_settings.merge( :enable_starttls_auto => true)
          end
      end

      describe 'with :enable_starttls_auto set to :auto' do
        specify 'sends mail' do
          @mailer.smtp.merge(:enable_starttls_auto => :auto)
          lambda { @mailer.call(@env) }.should.raise(TestError)
          @env['mail.sent'].should.be true
        end
      end

      describe 'with :enable_starttls_auto set to true' do
        specify 'sends mail' do
          @mailer.smtp.merge(:enable_starttls_auto => true)
          lambda { @mailer.call(@env) }.should.raise(TestError)
          @env['mail.sent'].should.be true
        end
      end
    end if defined?(TEST_SMTP_TLS)

    describe 'for tls enabled fake smtp' do
      class FakeSMTP
        def initialize(*args); @@_tls = nil; end
        def start(*args);  end
        def enable_starttls_auto; @@_tls = :auto; end
        def enable_starttls; @@_tls = true; end
        def send_message(*args); end
        def self.tls; @@_tls; end
      end

      setup do
        Rack::MailExceptions.class_eval { def service; FakeSMTP; end}
        @mailer = 
          Rack::MailExceptions.new(@app) do |mail|
            mail.to 'foo@example.org'
            mail.from 'bar@example.org'
            mail.subject '[ERROR] %s'
            mail.smtp @smtp_settings.merge( :server => 'server.com')
          end
      end

      context 'with :enable_starttls_auto unset' do
        specify 'sends mail' do
          @mailer.smtp[:enable_starttls_auto] = nil
          lambda { @mailer.call(@env) }.should.raise(TestError)
          FakeSMTP.tls.should.be nil
        end
      end

      context 'with :enable_starttls_auto set to true' do
        specify 'sends mail' do
          @mailer.smtp[:enable_starttls_auto] = true
          lambda { @mailer.call(@env) }.should.raise(TestError)
          FakeSMTP.tls.should == true
        end
      end

      context 'with :enable_starttls_auto set to :auto' do
        specify 'sends mail' do
          @mailer.smtp[:enable_starttls_auto] = :auto
          lambda { @mailer.call(@env) }.should.raise(TestError)
          FakeSMTP.tls.should == :auto
        end
      end
    end
  end
rescue LoadError => boom
  STDERR.puts "WARN: Skipping Rack::MailExceptions tests (tmail not installed)"
end
