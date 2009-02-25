#!/usr/bin/ruby

require 'rubygems'
require 'tap'

# extract_msn.exe -M0.2 -B85 -T4500 -S0 -G1 -I35 -C0 -P2 -D output smallraw.RAW

module Ms ; end
class Ms::Msrun ; end

# Documentation here
class Ms::Msrun::Search < Tap::Task
  
  #config :first_scan, 0, :short => 'F', &c.integer # first scan
  #config :last_scan, 1e12, :short => 'L', &c.integer  # last scan
  ## if not determined to be +1, then create these charge states
  #config( :charge_states, [2,3], :short => 'c') {|v| v.split(',') }
  #config :bottom_mh, 0, :short => 'B', &c.float # bottom MH+ 
  #config :top_mh, -1.0, :short => 'T', &c.float # top MH+
  #config :min_peaks, 0, :short => 'P', &c.integer # minimum peak count
  #config :ms_levels, 2..-1, :short => 'M', &c.range  # ms levels to export


  def process(filename)
    Ms::Msrun.open(filename) do |ms|
      ms.to_mgf(ms.filename.chomp(File.extname(ms.filename)))
    end
  end
end

Ms::Msrun::Search.execute


  #config :group_mass_tol, 1.4, :short => 'M', &c.float # prec. mass tolerance for grouping
  #config :bottom_mw, 0.0, :short => 'B', &c.float # bottom MW for data file creation
  #config :top_mw, 999999.0, :short => 'T', &c.float # top MW for data file creation
  #config :interm_scans, 0, :short => 'S', &c.integer # allowed num intermediate scans between groups
  #config :min_group, 1, :short => 'G', &c.integer # minimum # of related grouped scans needed for a .dta file
  #config :min_ions, 0, :short => 'I', &c.integer # minimum num of ions needed for a .dta file
  # What the heck is the -P option?? Not listed in the help!
  # Ahn lab sets this to: 2
  # config : :short => 'P', 

