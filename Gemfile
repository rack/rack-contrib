# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'i18n', '~> 0.6', '>= 0.6.8'
gem 'json', '~> 2.0'
gem 'mime-types', '~> 3.0'
gem 'minitest', '~> 5.6'
gem 'minitest-hooks', '~> 1.0'
gem 'mail', '~> 2.3', '>= 2.6.4'
gem 'nbio-csshttprequest', '~> 1.0'
gem 'rack', ENV['RACK_VERSION']
gem 'rake'
gem 'rdoc', '~> 5.0'
gem 'ruby-prof'
gem 'timecop', '~> 0.9'

# See https://github.com/ruby/cgi/pull/29
# Needed to have passing tests on Ruby 2.7, Ruby 3.0
gem 'cgi', '>= 0.3.6' if RUBY_VERSION >= '2.7.0' && RUBY_VERSION <= '3.1.0'

group :maintenance, optional: true do
  gem "bake"
  gem "bake-gem"
end
