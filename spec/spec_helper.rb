require 'rubygems'
require 'spec/more'

TESTFILES = File.expand_path(File.dirname(__FILE__)) + '/testfiles'

module Bacon
  class Context
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
