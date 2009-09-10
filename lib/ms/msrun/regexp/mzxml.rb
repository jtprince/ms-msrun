
require 'ms/msrun'
require 'ms/spectrum'
require 'ms/data'
require 'ms/data/lazy_io'
require 'ms/precursor'
require 'ms/mzxml'

module Ms
  class Msrun
    module Regexp
    end
  end
end

class Ms::Msrun::Regexp::Mzxml

  attr_accessor :msrun, :io, :version

  def initialize(msrun_object, io, version)
    @msrun = msrun_object
    @io = io
    @version = version
  end

  # returns the msrun
  def parse_header
    while line = @io.gets
      if line =~ %r{\s+fileName=['"](.*?)['"]}
        (bn, dn) = Ms::Mzxml.parent_basename_and_dir($1)
        @msrun.parent_basename = bn
        @msrun.parent_location = dn
      end
      if line =~ /\s+scanCount=['"](\w+)['"]/
        @msrun.scan_count = $1.to_i
      end
      if line =~ /startTime=['"]([\w\.]+)['"]/
        @msrun.start_time = $1[2...-1].to_f
      end
      if line =~ /endTime=['"]([\w\.]+)['"]/
        @msrun.end_time = $1[2...-1].to_f
      end
      if @io =~ /^\s*<scan/
        break
      end
    end
    @msrun
  end

  def self.parse_precursor(line)
    prec = Ms::Precursor.new
    loop do
      if line =~ /precursorIntensity=['"]([\d\.]+)['"]/
        prec[1] = $1.to_f
      end
      if line =~ /precursorCharge=["'](\d+)["']/
        prec[3] = [$1.to_i]
      end
      if line =~ %r{>([\d\.]+)</precursorMz>}
        prec[0] = $1.to_f
        break
      end
      line = io.gets
    end
  end

  def self.parse_peaks
    precision = 32
    byte_order = 'network'
    while line = @io.gets
      if line =~ /(precision|byteOrder)=["'](\w+)["']/
        case $1
        when 'precision'
          $2.to_i
        when 'byteOrder'
          byte_order = $2
        end
      end
      if line =~ %r{</peaks>}
        first_pos = line.index('>')
        last_pos = @io.pos + line.rindex("</peaks>")
        Ms::Spectrum
        break
      end
    end
  end

  
  # assumes that the io object has been set to the beginning of the scan
  # element.  Returns an Ms::Scan object
  def self.parse_scan(start_byte, length)
    @io.pos = start_byte
    hash = {}
    while line = @io.gets do
      if line =~ /^\s*<precursorMz/
        self.parse_precursor(line)
        self.parse_peaks
        break
      end
      if line =~ /(\w+)=["'](\w+)["']/
        hash[$1] = $2
      end
    end
    new_scan_from_hash(hash)
  end

  def new_scan_from_hash(hash)
    scan = Ms::Scan.new  # array class creates one with 9 positions
    scan[0] = hash['num'].to_i
    scan[1] = hash['msLevel'].to_i
    if x = hash['retentionTime']
      scan[2] = x[2...-1].to_f
    end
    if x = hash['startMz']
      scan[3] = x.to_f
      scan[4] = hash['endMz'].to_f
      scan[5] = hash['peaksCount'].to_i
      scan[6] = hash['totIonCurrent'].to_f
    end
    scan
  end


end


