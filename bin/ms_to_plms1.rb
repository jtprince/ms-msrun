#!/usr/bin/ruby

require "ms/msrun/plms1"

ext = "plms1"

if ARGV.size == 0
  puts "usage: #{File.basename(__FILE__)} <file>.mz[X]ML ..."
  puts "output: <file>.#{ext} ..."
  puts ""
  puts "    plms1 is the Prince Lab MS 1 binary file format"
  puts "    [matlab readers and writers also exist]"
  puts ""
  puts "options:"
  puts "  --spec     print file spec and exit"
end

if ARGV.include?("--spec")
  puts Ms::Msrun::Plms1::SPECIFICATION
  exit
end

ARGV.each do |file|
  outfile = file.sub(/\.mzX?ML$/,".#{ext}")
  Ms::Msrun.open(file) do |ms|
    # see docs for lots more options here
    ms.to_plms1.write(outfile)
  end
end
