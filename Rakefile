# Rakefile for Rack::Contrib.  -*-ruby-*-
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

require 'rubygems'
# load gemspec
$spec = eval(File.read('rack-contrib.gemspec'))

def package(ext='')
  "pkg/rack-contrib-#{$spec.version}" + ext
end

desc 'Build packages'
task :package => %w[.gem .tar.gz].map {|e| package(e)}

desc 'Build and install as local gem'
task :install => package('.gem') do
  sh "gem install #{package('.gem')}"
end

directory 'pkg/'

file package('.gem') => %w[pkg/ rack-contrib.gemspec] + $spec.files do |f|
  sh "gem build rack-contrib.gemspec"
  mv File.basename(f.name), f.name
end

file package('.tar.gz') => %w[pkg/] + $spec.files do |f|
  sh "git archive --format=tar HEAD | gzip > #{f.name}"
end

# GEMSPEC ===================================================================

file 'rack-contrib.gemspec' => FileList['{lib,test}/**','Rakefile', 'README.rdoc'] do |f|
  # read spec file and split out manifest section
  spec = File.read(f.name)
  parts = spec.split("  # = MANIFEST =\n")
  fail 'bad spec' if parts.length != 3
  # determine file list from git ls-files
  files = `git ls-files`.
    split("\n").sort.reject{ |file| file =~ /^\./ }.
    map{ |file| "    #{file}" }.join("\n")
  # piece file back together and write...
  parts[1] = "  s.files = %w[\n#{files}\n  ]\n"
  spec = parts.join("  # = MANIFEST =\n")
  spec.sub!(/s.date = '.*'/, "s.date = '#{Time.now.strftime("%Y-%m-%d")}'")
  File.open(f.name, 'w') { |io| io.write(spec) }
  puts "updated #{f.name}"
end
