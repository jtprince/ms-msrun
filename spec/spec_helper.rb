require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'spec/more'

TESTFILES = File.dirname(__FILE__) + '/testfiles'

thisdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(thisdir)
$LOAD_PATH.unshift(File.join(thisdir, '..', 'lib'))

Bacon.summary_on_exit
