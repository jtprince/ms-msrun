require 'rake'
require 'rubygems'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/clean'
require 'fileutils'
require 'email_encrypt'

###############################################
# GLOBAL
###############################################

FL = FileList
NAME = "ms-msrun"
FU = FileUtils

readme = "README"

rdoc_dir = 'rdoc'
rdoc_extra_includes = [readme, "LICENSE"]
rdoc_options = ['--main', readme, '--title', NAME, '--line-numbers', '--inline-source']

lib_files = FL["lib/**/*.rb"]
dist_files = lib_files + FL[readme, "LICENSE", "Rakefile", "{specs}/**/*"]
changelog = 'CHANGELOG'

###############################################
# DOC
###############################################
Rake::RDocTask.new do |rd|
  rd.rdoc_dir = rdoc_dir
  rd.main = readme
  rd.rdoc_files.include( rdoc_extra_includes )
  rd.rdoc_files.include( lib_files.uniq )
  rd.options.push( *rdoc_options )
end

desc "create and upload docs to server"
task :upload_docs => [:rdoc] do
  sh "scp -r #{rdoc_dir}/* jtprince@rubyforge.org:/var/www/gforge-projects/mspire/ms-msrun/"
end

###############################################
# TESTS
###############################################

desc 'Default: Run specs.'
task :default => :spec

desc 'Run specs.'
Rake::TestTask.new(:spec) do |t|
  t.verbose = true
  t.warning = true
  ENV['RUBYOPT'] = 'rubygems'
  ENV['TEST'] = ENV['SPEC'] if ENV['SPEC']
  t.libs = ['lib']
  t.test_files = Dir.glob( File.join('spec', ENV['pattern'] || '**/*_spec.rb') )
  t.options = "-v"
end

###############################################
# PACKAGE / INSTALL / UNINSTALL
###############################################

tm = Time.now
gemspec = Gem::Specification.new do |t|
  description = 'A library for working with LC/MS runs. Part of mspire.  Has parsers for mzXML v1, 2, and 3, mzData and mzML.  Can convert to commonly desired search output (such as mgf)'
  summary = "A library for working with LC/MS runs"
  t.platform = Gem::Platform::RUBY
  t.name = NAME
  t.version =  IO.readlines(changelog).grep(/##.*version/).pop.split(/\s+/).last.chomp
  t.homepage = 'http://mspire.rubyforge.org/projects/ms-msrun'
  t.rubyforge_project = 'mspire'
  t.summary = summary
  t.date = "#{tm.year}-#{tm.month}-#{tm.day}"
  t.email = "jtprince@gmail.com"
  t.description = description
  t.has_rdoc = true
  t.authors = ["John Prince"]
  t.files = dist_files
  t.add_dependency 'axml', '~> 0.0.5'
  t.rdoc_options = rdoc_options
  t.extra_rdoc_files = rdoc_extra_includes
  t.executables = FL["bin/*"].map {|file| File.basename(file) }
  t.requirements << 'xmlparser or libxml'
  t.test_files = FL["spec/**/*_spec.rb"]
end

desc "Create packages."
Rake::GemPackageTask.new(gemspec) do |pkg|
  #pkg.need_zip = true
  pkg.need_tar = true
end

task :remove_pkg do 
  FileUtils.rm_rf "pkg"
end

task :install => [:reinstall]

desc "uninstalls the package, packages a fresh one, and installs"
task :reinstall => [:remove_pkg, :clean, :package] do
  reply = `#{$gemcmd} list -l #{NAME}`
  if reply.include?(NAME + " (")
    %x( #{$gemcmd} uninstall -a -x #{NAME} )
  end
  FileUtils.cd("pkg") do
    cmd = "#{$gemcmd} install #{NAME}*.gem"
    puts "EXECUTING: #{cmd}" 
    system cmd
  end
end

