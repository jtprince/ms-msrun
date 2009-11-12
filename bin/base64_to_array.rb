#!/usr/bin/ruby

require 'ms/data/lazy_string'

if ARGV.size == 0
  puts "usage: #{File.basename(__FILE__)} <base64_string>"
  puts "outputs the array of values"
  exit
end

ar = Ms::Data::LazyString.new(ARGV.shift).to_a
puts "[ " + ar.join(", ") + " ]"
