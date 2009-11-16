require 'rubygems'
require 'rake'

require 'jeweler'
require 'fileutils'

#require 'rake/rdoctask'
#require 'rake/gempackagetask'
#require 'rake/testtask'
#require 'rake/clean'

###############################################
# GLOBAL
###############################################

NAME = "ms-msrun"

readme = "README"

rdoc_dir = 'rdoc'
rdoc_extra_includes = [readme, "LICENSE"]
rdoc_options = ['--main', readme, '--title', NAME, '--line-numbers', '--inline-source']

lib_files = FileList["lib/**/*.rb"]
dist_files = lib_files + FileList[readme, "LICENSE", "Rakefile", "{specs}/**/*"]
history = 'History'


Jeweler::Tasks.new do |gem|
  tm = Time.now
  gem.name = NAME
  gem.summary = "an mspire library for working with LC/MS runs (mzxml, mzData, mzML)"
  gem.description = 'A library for working with LC/MS runs. Part of mspire.  Has parsers for mzXML v1, 2, and 3, mzData (currently broken) and mzML (planned).  Can convert to commonly desired search output (such as mgf).  Fast random access of scans, and fast reading of the entire file.'
  gem.email = "jtprince@gmail.com"
  gem.homepage = 'http://mspire.rubyforge.org/projects/ms-msrun'
  gem.authors = ["John Prince"]
  t.version =  IO.readlines(history).grep(/##.*version/).pop.split(/\s+/).last.chomp
    t.homepage = 'http://mspire.rubyforge.org/projects/ms-msrun'
  t.rubyforge_project = 'mspire'
  t.summary = summary
  t.date = "#{tm.year}-#{tm.month}-#{tm.day}"
  t.email = "jtprince@gmail.com"
  t.description = description
  t.has_rdoc = true
  t.authors = ["John Prince"]
  t.files = dist_files
  t.add_dependency 'ms-core'
  t.add_dependency 'nokogiri'
  t.add_dependency 'runarray'
  t.rdoc_options = rdoc_options
  t.extra_rdoc_files = rdoc_extra_includes
  t.executables = FileList["bin/*"].map {|file| File.basename(file) }
  t.test_files = FileList["spec/**/*_spec.rb"]

end











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


desc "Publish RDoc to RubyForge"
task :publish_rdoc => [:rdoc] do
  require 'yaml'
  
  config = YAML.load(File.read(File.expand_path("~/.rubyforge/user-config.yml")))
  host = "#{config["username"]}@rubyforge.org"
  
  rsync_args = "-v -c -r"
  remote_dir = "/var/www/gforge-projects/mspire/projects/#{NAME}"
  local_dir = "rdoc"
 
  sh %{rsync #{rsync_args} #{local_dir}/ #{host}:#{remote_dir}}
end

#desc "create and upload docs to server"
#task :upload_docs => [:rdoc] do
#  sh "scp -r #{rdoc_dir}/* jtprince@rubyforge.org:/var/www/gforge-projects/mspire/projects/ms-msrun/"
#end

###############################################
# TESTS
###############################################

desc 'Default: Run specs.'
task :default => :spec

desc 'Run specs.'
Rake::TestTask.new(:spec) do |t|
  #t.verbose = true
  #t.warning = true
  ENV['TEST'] = ENV['SPEC'] if ENV['SPEC']
  t.libs = ['lib']
  t.test_files = Dir.glob( File.join('spec', ENV['pattern'] || '**/*_spec.rb') )
  #t.options = "-v"
end

###############################################
# PACKAGE / INSTALL / UNINSTALL
###############################################

gemspec = Gem::Specification.new do |t|
  summary = "A library for working with LC/MS runs"
  t.platform = Gem::Platform::RUBY
  t.name = NAME
  t.version =  IO.readlines(history).grep(/##.*version/).pop.split(/\s+/).last.chomp
  t.homepage = 'http://mspire.rubyforge.org/projects/ms-msrun'
  t.rubyforge_project = 'mspire'
  t.summary = summary
  t.date = "#{tm.year}-#{tm.month}-#{tm.day}"
  t.email = "jtprince@gmail.com"
  t.description = description
  t.has_rdoc = true
  t.authors = ["John Prince"]
  t.files = dist_files
  t.add_dependency 'ms-core'
  t.add_dependency 'nokogiri'
  t.add_dependency 'runarray'
  t.rdoc_options = rdoc_options
  t.extra_rdoc_files = rdoc_extra_includes
  t.executables = FileList["bin/*"].map {|file| File.basename(file) }
  t.test_files = FileList["spec/**/*_spec.rb"]
end

desc "Create packages."
Rake::GemPackageTask.new(gemspec) do |pkg|
  #pkg.need_zip = true
  #pkg.need_tar = true
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

