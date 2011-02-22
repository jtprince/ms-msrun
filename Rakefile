require 'rubygems'
require 'bundler'
require 'rake'
require 'jeweler'
require 'rake/testtask'
#require 'rcov/rcovtask'

require 'jeweler'
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

require 'rake/testtask'
Rake::TestTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

#Rcov::RcovTask.new do |spec|
#  spec.libs << 'spec'
#  spec.pattern = 'spec/**/*_spec.rb'
#  spec.verbose = true
#end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ms-msrun #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
