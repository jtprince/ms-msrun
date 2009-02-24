#!/usr/bin/ruby

require 'rubygems'
require 'tap'

# extract_msn.exe -M0.2 -B85 -T4500 -S0 -G1 -I35 -C0 -P2 -D output smallraw.RAW

module Ms ; end
module Ms::Msrun ; end

# Goodnight::manifest a goodnight moon script
# Says goodnight with a configurable message.
class Ms::Msrun::Search < Tap::Task
  config :group_mass_tol, 1.4, :short => 'M', &c.float # prec. mass tolerance for grouping
  config :bottom_mw, nil, :short => 'B', &c.float # bottom MW for data file creation
  config :top_mw, nil, :short => 'T', &c.float # top MW for data file creation
  config :interm_scans, 0, :short => 'S', &c.integer
  config :min_group, 1, :short => 'G', &c.integer # minimum # of related grouped scans needed for a .dta file
  config :min_ions, 0 :short => 'I', &c.integer # minimum # of ions needed for a .dta file
  config : :short => 'P'

  def process(obj)


  end
end

Goodnight.execute
