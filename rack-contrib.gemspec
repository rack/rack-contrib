Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name = 'rack-contrib'
  s.version = '0.4.0'
  s.date = '2008-12-09'

  s.description = "Contributed Rack Middleware and Utilities"
  s.summary     = "Contributed Rack Middleware and Utilities"

  s.authors = ["rack-devel"]
  s.email = "rack-devel@googlegroups.com"

  # = MANIFEST =
  s.files = %w[
    COPYING
    README.rdoc
    Rakefile
    lib/rack/contrib.rb
    lib/rack/etag.rb
    lib/rack/jsonp.rb
    lib/rack/lighttpd_script_name_fix.rb
    lib/rack/locale.rb
    lib/rack/mailexceptions.rb
    lib/rack/post_body_content_type_parser.rb
    lib/rack/profiler.rb
    lib/rack/sendfile.rb
    lib/rack/time_zone.rb
    rack-contrib.gemspec
    test/mail_settings.rb
    test/spec_rack_contrib.rb
    test/spec_rack_etag.rb
    test/spec_rack_jsonp.rb
    test/spec_rack_lighttpd_script_name_fix.rb
    test/spec_rack_mailexceptions.rb
    test/spec_rack_post_body_content_type_parser.rb
    test/spec_rack_sendfile.rb
  ]
  # = MANIFEST =

  s.test_files = s.files.select {|path| path =~ /^test\/spec_.*\.rb/}

  s.extra_rdoc_files = %w[README.rdoc COPYING]
  s.add_dependency 'rack', '~> 0.4'
  s.add_dependency 'tmail', '>= 1.2'
  s.add_dependency 'json', '>= 1.1'

  s.has_rdoc = true
  s.homepage = "http://github.com/rtomayko/rack-contrib/"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "rack-contrib", "--main", "README"]
  s.require_paths = %w[lib]
  s.rubygems_version = '1.1.1'
end
