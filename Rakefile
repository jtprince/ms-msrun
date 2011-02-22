require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'
require 'jeweler'

NAME = "ms-msrun"
WEBSITE_BASE = "website"
WEBSITE_OUTPUT = WEBSITE_BASE + "/output"

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "ms-msrun"
  gem.homepage = "http://github.com/jtprince/ms-msrun"
  gem.license = "MIT"
  gem.summary = %Q{an mspire library for working with LC/MS runs (mzxml & mzML)}
  gem.description = %Q{A library for working with LC/MS runs. Part of mspire.  Has parsers for mzXML v1, 2, and 3 and mzML.  Can convert to commonly desired search output (such as mgf).  Fast random access of scans, and fast reading of the entire file.}
  gem.email = "jtprince@gmail.com"
  gem.authors = ["John T. Prince"]
  gem.rubyforge_project = 'mspire'
  # I THINK THE BELOW IS OBSOLETED BY BUNDLER:
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  gem.add_runtime_dependency 'jabber4r', '> 0.1'
  #  gem.add_development_dependency 'rspec', '> 1.2.3'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |spec|
  spec.libs << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

def rdoc_redirect(base_rdoc_output_dir, package_website_page, version)
  content = %Q{
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html><head><title>mspire: } + NAME + %Q{rdoc</title>
<meta http-equiv="REFRESH" content="0;url=#{package_website_page}/rdoc/#{version}/">
</head> </html> 
  }
  FileUtils.mkpath(base_rdoc_output_dir)
  File.open(base_rdoc_output_dir + "/index.html", 'w') {|out| out.print content }
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  base_rdoc_output_dir = WEBSITE_OUTPUT + '/rdoc'
  version = File.read('VERSION')
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = NAME + ' ' + version
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :create_redirect do
  base_rdoc_output_dir = WEBSITE_OUTPUT + '/rdoc'
  rdoc_redirect(base_rdoc_output_dir, gemspec.homepage,version)
end

namespace :website do
  desc "checkout and configure the gh-pages submodule (assumes you have it)"
  task :submodule_update do
    if File.exist?(WEBSITE_OUTPUT + "/.git")
      puts "!! not doing anything, #{WEBSITE_OUTPUT + "/.git"} already exists !!"
    else

      puts "(not sure why this won't work programmatically)"
      puts "################################################"
      puts "[Execute these commands]"
      puts "################################################"
      puts "git submodule init"
      puts "git submodule update"
      puts "pushd #{WEBSITE_OUTPUT}"
      puts "git co --track -b gh-pages origin/gh-pages ;"
      puts "popd"
      puts "################################################"

      # not sure why this won't work!
      #%x{git submodule init}
      #%x{git submodule update}
      #Dir.chdir(WEBSITE_OUTPUT) do
      #  %x{git co --track -b gh-pages origin/gh-pages ;}
      #end
    end
  end

  desc "setup your initial gh-pages"
  task :init_ghpages do
    puts "################################################"
    puts "[Execute these commands]"
    puts "################################################"
    puts "git symbolic-ref HEAD refs/heads/gh-pages"
    puts "rm .git/index"
    puts "git clean -fdx"
    puts 'echo "Hello" > index.html'
    puts "git add ."
    puts 'git commit -a -m "my first gh-page"'
    puts "git push origin gh-pages"
  end

end

task :default => :spec

task :build => :gemspec

# credit: Rakefile modeled after Jeweler's

