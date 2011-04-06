require 'rubygems'
require 'spec/more'

thisdir = File.dirname(__FILE__)

$LOAD_PATH.unshift(thisdir)
$LOAD_PATH.unshift(File.join(thisdir, '..', 'lib'))

Bacon.summary_on_exit

TESTFILES = File.dirname(__FILE__) + '/testfiles'
