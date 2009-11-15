
require 'rubygems'
require 'bacon'

TESTFILES = File.expand_path(File.dirname(__FILE__)) + '/testfiles'

def xit(*args, &block)
  puts "SKIPPING: #{args}"
end

class Object
  def is(other)
    should.equal other
  end
  def ok
    should.equal true
  end
end

Bacon.summary_on_exit
