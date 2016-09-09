begin
	require 'git-version-bump'
rescue LoadError
	nil
end

Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name    = 'rack-contrib'
  s.version = GVB.version rescue "0.0.0.1.ENOGVB"
  s.date    = GVB.date    rescue Time.now.strftime("%F")

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

  # REMINDER: If you modify any dependencies, please ensure you
  # update `test/gemfiles/minimum_versions`!
  #
  s.add_runtime_dependency 'rack', '>= 1.4'
  s.add_runtime_dependency 'git-version-bump', '~> 0.15'

  s.add_development_dependency 'bundler', '~> 1.0'
  s.add_development_dependency 'github-release', '~> 0.1'
  s.add_development_dependency 'i18n', '~> 0.4'
  s.add_development_dependency 'json', '~> 1.8'
  s.add_development_dependency 'minitest', '~> 5.6'
  s.add_development_dependency 'minitest-hooks', '~> 1.0'
  s.add_development_dependency 'mail', '~> 2.3'
  s.add_development_dependency 'nbio-csshttprequest', '~> 1.0'
  s.add_development_dependency 'rake', '~> 10.4', '>= 10.4.2'
  s.add_development_dependency 'rdoc', '~> 3.12'
  s.add_development_dependency 'ruby-prof', '~> 0.13.0'

  s.has_rdoc = true
  s.homepage = "http://github.com/rack/rack-contrib/"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "rack-contrib", "--main", "README"]
  s.require_paths = %w[lib]
  s.rubygems_version = '1.1.1'
end
