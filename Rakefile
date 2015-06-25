# -*-ruby-*-
exec(*(["bundle", "exec", $PROGRAM_NAME] + ARGV)) if ENV['BUNDLE_GEMFILE'].nil?

begin
	Bundler.setup(:default, :development)
rescue Bundler::BundlerError => ex
	$stderr.puts e.message
	$stderr.puts "Run `bundle install` to install missing gems"
	exit e.status_code
end

require 'rdoc/task'
require 'rake/testtask'

desc "Run all the tests"
task :default => [:test]

desc "Run specs"
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/spec_*.rb']
end

desc "Generate RDoc documentation"
RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.options << '--line-numbers' << '--inline-source' <<
    '--main' << 'README' <<
    '--title' << 'Rack Contrib Documentation' <<
    '--charset' << 'utf-8'
  rdoc.rdoc_dir = "doc"
  rdoc.rdoc_files.include 'README.rdoc'
  rdoc.rdoc_files.include('lib/rack/*.rb')
  rdoc.rdoc_files.include('lib/rack/*/*.rb')
end


# PACKAGING =================================================================

Bundler::GemHelper.install_tasks

task :release do
	sh "git release"
end
