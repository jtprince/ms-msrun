
require 'nokogiri'
require 'ms/msrun'
require 'ms/spectrum'
require 'ms/data'
require 'ms/data/lazy_io'
require 'ms/precursor'
require 'ms/mzxml'

module Ms
  class Msrun
    module Nokogiri
    end
  end
end

class Ms::Msrun::Nokogiri::Mzxml
  NetworkOrder = true

  attr_accessor :msrun, :io, :version

  def initialize(msrun_object, io, version)
    @msrun = msrun_object
    @io = io
    @version = version
  end

  # returns the msrun
  def parse_header(length_of_header)
    io.rewind
    Nio.read(length_of_header)
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

  def parse_peaks
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

  # we have to do this because nokogiri doesn't keep track of the byte
  # position for us!
  def peak_start_and_length(string)
    end_pos = string.rindex("</peak>")
    string.rindex(">", end_pos)
  end
  
  # assumes that the io object has been set to the beginning of the scan
  # element.  Returns an Ms::Scan object
  def parse_scan(start_byte, length)
    string = io.read(length, start_byte)
    node_set = Nokogiri::XML.parse(string, nil, nil, Nokogiri::XML::ParseOptions::DEFAULT_XML | Nokogiri::XML::ParseOptions::NOBLANKS )

    scan_n = node_set.child
    scan = new_scan_from_node( scan_n )

    prec_n = scan_n / "child::precursorMz"
    prec = Ms::Precursor.new
    prec[1] = node['precursorIntensity'].to_f
    prec[0] = node.text.to_f
    if x = node['precursorCharge']
      prec[3] = [x.to_i]
    end
    # is this for mzData?
    #if x = node['precursorScanNum']
    #  prec[2] = scans_by_num[x.to_i]
    #end
    (start, length) = peak_start_and_length(string)
    data = Ms::Data::LazyIO.new(io, <start_byte>, <length>, Ms::Data::LazyIO.unpack_code(peak_n['precision'].to_i, NetworkOrder))
    scan[8] = Ms::Spectrum.new(Ms::Data::Interleaved.new(data))
    scan
  end

  def new_scan_from_node(node)
    scan = Ms::Scan.new  # array class creates one with 9 positions
    scan[0] = node['num'].to_i
    scan[1] = node['msLevel'].to_i
    if x = node['retentionTime']
      scan[2] = x[2...-1].to_f
    end
    if x = node['startMz']
      scan[3] = x.to_f
      scan[4] = node['endMz'].to_f
      scan[5] = node['peaksCount'].to_i
      scan[6] = node['totIonCurrent'].to_f
    end
    scan
  end


end


