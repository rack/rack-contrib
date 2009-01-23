Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name = 'rack-contrib'
  s.version = '0.9.0'
  s.date = '2009-01-23'

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
    lib/rack/contrib/bounce_favicon.rb
    lib/rack/contrib/callbacks.rb
    lib/rack/contrib/etag.rb
    lib/rack/contrib/evil.rb
    lib/rack/contrib/garbagecollector.rb
    lib/rack/contrib/jsonp.rb
    lib/rack/contrib/lighttpd_script_name_fix.rb
    lib/rack/contrib/locale.rb
    lib/rack/contrib/mailexceptions.rb
    lib/rack/contrib/nested_params.rb
    lib/rack/contrib/post_body_content_type_parser.rb
    lib/rack/contrib/proctitle.rb
    lib/rack/contrib/profiler.rb
    lib/rack/contrib/route_exceptions.rb
    lib/rack/contrib/sendfile.rb
    lib/rack/contrib/time_zone.rb
    rack-contrib.gemspec
    test/mail_settings.rb
    test/spec_rack_callbacks.rb
    test/spec_rack_contrib.rb
    test/spec_rack_etag.rb
    test/spec_rack_evil.rb
    test/spec_rack_garbagecollector.rb
    test/spec_rack_jsonp.rb
    test/spec_rack_lighttpd_script_name_fix.rb
    test/spec_rack_mailexceptions.rb
    test/spec_rack_nested_params.rb
    test/spec_rack_post_body_content_type_parser.rb
    test/spec_rack_proctitle.rb
    test/spec_rack_profiler.rb
    test/spec_rack_sendfile.rb
  ]
  # = MANIFEST =

  s.test_files = s.files.select {|path| path =~ /^test\/spec_.*\.rb/}

  s.extra_rdoc_files = %w[README.rdoc COPYING]
  s.add_dependency 'rack', '~> 0.9.1'
  s.add_dependency 'test-spec', '~> 0.9.0'
  s.add_development_dependency 'tmail', '>= 1.2'
  s.add_development_dependency 'json', '>= 1.1'

  s.has_rdoc = true
  s.homepage = "http://github.com/rack/rack-contrib/"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "rack-contrib", "--main", "README"]
  s.require_paths = %w[lib]
  s.rubygems_version = '1.1.1'
end
