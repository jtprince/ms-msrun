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
          
          if v.is_a?(Float)
            obj.send(k.to_sym).should.be.close v, 0.00000001
          else
            puts "\n**********************************\n#{k}: #{v} but was #{obj.send(k.to_sym)}" if obj.send(k.to_sym) != v
            obj.send(k.to_sym).should.equal v
          end
        end
      end
    end
  end
end

class File
  # unlinks the file and won't complain if it doesn't exist
  def self.unlink_f(file)
    if File.exist?(file)
      File.unlink(file)
    end
  end
end

Bacon.summary_on_exit
