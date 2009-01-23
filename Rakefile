# Rakefile for Rack::Contrib.  -*-ruby-*-
require 'rake/rdoctask'
require 'rake/testtask'

desc "Run all the tests"
task :default => [:test]

desc "Generate RDox"
task "RDOX" do
  sh "specrb -Ilib:test -a --rdox >RDOX"
end

desc "Run all the fast tests"
task :test do
  sh "specrb -Ilib:test -w #{ENV['TEST'] || '-a'} #{ENV['TESTOPTS']}"
end

desc "Run all the tests"
task :fulltest do
  sh "specrb -Ilib:test -w #{ENV['TEST'] || '-a'} #{ENV['TESTOPTS']}"
end

desc "Generate RDoc documentation"
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.options << '--line-numbers' << '--inline-source' <<
    '--main' << 'README' <<
    '--title' << 'Rack Contrib Documentation' <<
    '--charset' << 'utf-8'
  rdoc.rdoc_dir = "doc"
  rdoc.rdoc_files.include 'README.rdoc'
  rdoc.rdoc_files.include 'RDOX'
  rdoc.rdoc_files.include('lib/rack/*.rb')
  rdoc.rdoc_files.include('lib/rack/*/*.rb')
end
task :rdoc => ["RDOX"]


# PACKAGING =================================================================

# load gemspec like github's gem builder to surface any SAFE issues.
require 'rubygems/specification'
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

desc 'Publish gem and tarball to rubyforge'
task 'publish:gem' => [package('.gem'), package('.tar.gz')] do |t|
  sh <<-end
    rubyforge add_release rack rack-contrib #{$spec.version} #{package('.gem')} &&
    rubyforge add_file    rack rack-contrib #{$spec.version} #{package('.tar.gz')}
  end
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
