# frozen_string_literal: true

require_relative 'lib/rack/contrib/version'

Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name    = 'rack-contrib'
  s.version = Rack::Contrib::VERSION

  s.licenses = ['MIT']

  s.description = "Contributed Rack Middleware and Utilities"
  s.summary     = "Contributed Rack Middleware and Utilities"

  s.authors = ["rack-devel"]
  s.email = "rack-devel@googlegroups.com"

  # = MANIFEST =
  s.files = %w[
    AUTHORS
    COPYING
    README.md
  ] + `git ls-files -z lib`.split("\0")

  s.test_files = s.files.select {|path| path =~ /^test\/spec_.*\.rb/}

  s.extra_rdoc_files = %w[README.md COPYING]

  s.required_ruby_version = '>= 2.2.2'

  s.add_runtime_dependency 'rack', '< 4'

  s.homepage = "https://github.com/rack/rack-contrib/"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "rack-contrib", "--main", "README"]
  s.require_paths = %w[lib]
  s.rubygems_version = '1.1.1'
end
