#!/usr/bin/ruby

require 'rubygems'
require 'ms/msrun'
require 'lmat'
require 'optparse'
require 'ostruct'
require 'runarray'

# defaults:
opt = {}
opt[:baseline] = 0.0
opt[:newext] = ".lmat"
opt[:inc_mz] = 1.0

# get options:
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} [options] <msfile> ..."
  op.separator "input: .mzdata or .mzXML"
  op.separator ""
  op.separator "(sums m/z values that round to the same bin)"
  op.separator ""
  op.on("--mz-inc N", Float, "m/z increment (def: 1.0)") {|n| opt[:mz_inc] = n.to_f}
  op.on("--mz-start N", Float, "m/z start (otherwise auto)") {|n| opt[:start_mz] = n.to_f}
  op.on("--mz-end N", Float, "m/z end (otherwise auto)") {|n| opt[:end_mz] = n.to_f}
  op.on("--baseline N", Float, "value for missing indices (def: #{opt[:baseline]})") {|n| opt[:baseline] = n.to_f}
  op.on("--ascii", "generates an lmata file instead") {opt[:ascii] = true}
  op.on("-v", "--verbose") {$VERBOSE = true}
end
opts.parse!

if ARGV.size < 1 
  puts opts
end

ARGV.each do |file|
  Ms::Msrun.open(file) do |msrun|
    mslevel = 1
    lmat = Lmat.new
    puts "WORK1"
    t = Time.now
    lmat.from_msrun(msrun, opt)
    print "Took: #{Time.now - t} sec"
    puts "WORK2"
    ext = File.extname(file)
    outfile = file.sub(/#{Regexp.escape(ext)}$/, opt[:newext])
      if opt[:ascii]
        outfile << "a"
        lmat.print(outfile)
      else
        lmat.write(outfile)
      end
    puts("OUTPUT: #{outfile}") if $VERBOSE
  end
end








