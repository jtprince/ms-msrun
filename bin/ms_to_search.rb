#!/usr/bin/ruby

require 'rubygems'
require 'tap'

# extract_msn.exe -M0.2 -B85 -T4500 -S0 -G1 -I35 -C0 -P2 -D output smallraw.RAW

module Ms ; end
class Ms::Msrun ; end

# Documentation here
class Ms::Msrun::Search < Tap::Task
  config :first_scan, 0, :short => 'F', &c.integer # first scan
  config :last_scan, 1e12, :short => 'L', &c.integer  # last scan
  config :charge_states, [2,3], :short => 'c', {|v| v.split(',') }
  config :bottom_mh, 0, :short => 'B', &c.float  # bottom MH+ 
  config :top_mh, 


  #config :group_mass_tol, 1.4, :short => 'M', &c.float # prec. mass tolerance for grouping
  #config :bottom_mw, 0.0, :short => 'B', &c.float # bottom MW for data file creation
  #config :top_mw, 999999.0, :short => 'T', &c.float # top MW for data file creation
  #config :interm_scans, 0, :short => 'S', &c.integer # allowed num intermediate scans between groups
  #config :min_group, 1, :short => 'G', &c.integer # minimum # of related grouped scans needed for a .dta file
  #config :min_ions, 0, :short => 'I', &c.integer # minimum num of ions needed for a .dta file
  # What the heck is the -P option?? Not listed in the help!
  # Ahn lab sets this to: 2
  # config : :short => 'P', 

  def process(filename)
    raise NotImplementedError, "haven't implemented interm_scans > 0" if interm_scans > 0
    Ms::Msrun.open(filename) do |ms|
      File.open(ms.basename_noext + '.mgf', 'w') do |out|
        prev_prec_mass = nil
        prev_group = nil
        ms.scans.each do |scan|
          next if scan.ms_level <= 1 || scan.num_peaks < min_ions
          mz, inten = scan.mzs_and_intensities(true)
          prec_mz = scan.precursor.mz
          if prev_prec_mass && (prev_prec_mass - prec_mz).abs <= group_mass_tol
            prev_group << [mz, inten]
          end
          prev_groups << [mz, inten]
          prev_prec_masses.unshift prec_mz
          prev_prec_masses.pop
        end
      end
    end
  end
end

Ms::Msrun::Search.execute
