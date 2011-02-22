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

TESTFILES = File.expand_path(File.dirname(__FILE__)) + '/testfiles'

module Bacon
  class Context
    def hash_match(hash, obj)
      hash.each do |k,v|
        if v.is_a?(Hash)
          hash_match(v, obj.send(k.to_sym))
        else
          
          if v.is_a?(Float)
            actual = obj.send(k.to_sym)
            if actual.nil?
              actual.is v  # this will be a more informative fail
            else
              actual.should.be.close v, 0.00000001
            end
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


