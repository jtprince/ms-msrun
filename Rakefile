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
  gem.summary = %Q{interface for working with mzML, mzXML, and spectra in general}
  gem.description = %Q{an mspire library for working with mzML, mzXML, and spectra in general}
  gem.email = "jtprince@gmail.com"
  gem.authors = ["John T. Prince"]
  gem.rubyforge_project = 'mspire'
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
