require 'rubygems'
require 'bacon'

TESTFILES = File.expand_path(File.dirname(__FILE__)) + '/testfiles'

def xit(*args, &block)
  puts "SKIPPING: #{args}"
end

def xdescribe(*args, &block)
  puts "SKIPPING DESCRIBE: #{args}"
end

class Object
  
  def is(other)
    should.equal other
  end

  def matches(other)
    should.match other
  end

  # an element wise matching
  def vals_are(other)
    cnt = 0
    other.each do |v|
      self[cnt].should.equal v
      cnt += 1
    end
  end

  def ok
    should.equal true
  end
end

module Bacon
  class Context
    def ok(arg)
      arg.should.equal true
    end

    def hash_match(hash, obj)
      hash.each do |k,v|
        if v.is_a?(Hash)
          hash_match(v, obj.send(k.to_sym))
        else
          puts "#{k}: #{v} but was #{obj.send(k.to_sym)}" if obj.send(k.to_sym) != v
          obj.send(k.to_sym).should.equal v
        end
      end
    end

  end
end

Bacon.summary_on_exit
