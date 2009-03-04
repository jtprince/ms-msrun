
require 'ms/spectrum'

if ARGV.size == 0
  puts "usage: #{File.basename(__FILE__)} <base64_string>"
  puts "outputs the array of values"
  exit
end

precision = 32
network_order = true
ar = Ms::Spectrum.base64_to_array(ARGV.shift, precision, network_order)
puts "[ " + ar.join(", ") + " ]"
