#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'ms/msrun/search'

opt = { :format => :mgf }

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} <file>.mzXML ..."
  op.separator "outputs: <file>.mgf"
  op.on("-f", "--format <mgf|ms2>", "the format type") {|v| opt[:format] = v.to_sym }
  # the default is set in ms/msrun/search.rb -> set_opts
  op.on("--no-filter-zeros", "won't remove values with zero intensity") {|v| opt[:filter_zero_intensity] = false }
  # the default is set in ms/msrun/search.rb -> set_opts
  op.on("--no-retention-times", "won't include RT even if available") {|v| opt[:retention_times] = false }
end

opts.parse!

if ARGV.size == 0
  puts opts
  exit
end

ARGV.each do |file|
  if File.exist?(file)
    Ms::Msrun::Search.convert(opt[:format], file, opt)
  else
    puts "missing file: #{file} [skipping]"
  end
end

# extract_msn.exe -M0.2 -B85 -T4500 -S0 -G1 -I35 -C0 -P2 -D output smallraw.RAW

  #config :group_mass_tol, 1.4, :short => 'M', &c.float # prec. mass tolerance for grouping
  #config :bottom_mw, 0.0, :short => 'B', &c.float # bottom MW for data file creation
  #config :top_mw, 999999.0, :short => 'T', &c.float # top MW for data file creation
  #config :interm_scans, 0, :short => 'S', &c.integer # allowed num intermediate scans between groups
  #config :min_group, 1, :short => 'G', &c.integer # minimum # of related grouped scans needed for a .dta file
  #config :min_ions, 0, :short => 'I', &c.integer # minimum num of ions needed for a .dta file
  # What the heck is the -P option?? Not listed in the help!
  # Ahn lab sets this to: 2
  # config : :short => 'P', 

