source 'https://rubygems.org'

gemspec

gem 'rack', '~> 1.4', :platforms => [:ruby_19, :ruby_21]
# 2.6.4 breaks ruby 1.9 support because it requires mime-types 3+
# which requires ruby > 2.
# See https://github.com/mikel/mail/issues/990 for details
#
# This has been fixed in current master but not released yet.
# See https://github.com/mikel/mail/commit/0277b8ee3204a3971fdfd6d92fd65ef80e9e9879
gem 'mail', '<= 2.6.3', :platforms => :ruby_19
