require 'rubygems'
require 'rake'
require 'jeweler'
require 'rake/testtask'
require 'rcov/rcovtask'

NAME = "ms-msrun"
WEBSITE_BASE = "website"
WEBSITE_OUTPUT = WEBSITE_BASE + "/output"

gemspec = Gem::Specification.new do |s|
  s.name = NAME
  s.authors = ["John T. Prince"]
  s.email = "jtprince@gmail.com"
  s.homepage = "http://jtprince.github.com/" + NAME + "/"
  s.summary = "an mspire library for working with LC/MS runs (mzxml, mzData, mzML)"
  s.description = 'A library for working with LC/MS runs. Part of mspire.  Has parsers for mzXML v1, 2, and 3, mzData (currently broken) and mzML (planned).  Can convert to commonly desired search output (such as mgf).  Fast random access of scans, and fast reading of the entire file.'
  s.rubyforge_project = 'mspire'
  s.add_dependency 'ms-core'
  s.add_dependency 'nokogiri'
  s.add_dependency 'narray'
  s.add_development_dependency("spec-more")
end

Jeweler::Tasks.new(gemspec)

Rake::TestTask.new(:spec) do |spec|
  ENV['TEST'] = ENV['SPEC'] if ENV['SPEC']  
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

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

