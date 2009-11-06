#!/usr/bin/ruby

require 'rubygems'
require 'optparse'
require 'ms/msrun/search'

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} <file>.mzXML ..."
  op.separator "outputs: <file>.mgf"
  op.separator "[by default outputs .mgf file]"

end

if ARGV.size == 0
  puts opts.to_s
  exit
end

ARGV.each do |file|
  Ms::Msrun.open(file) do |ms|
    outfile = ms.to_mgf(file.sub(/\.mzxml/i, '.mgf'))
    ms.to_mgf(outfile)
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

