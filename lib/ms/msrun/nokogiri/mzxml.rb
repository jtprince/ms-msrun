
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
      NOBLANKS = ::Nokogiri::XML::ParseOptions::DEFAULT_XML | ::Nokogiri::XML::ParseOptions::NOBLANKS
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
  def parse_header(byte_length_or_header_string)
    string = 
      if byte_length_or_header_string.is_a? Integer
        @io.rewind
        @io.read(byte_length_or_header_string)
      else
        length_or_header_string
      end
    doc = Nokogiri::XML.parse(string, nil, nil, Ms::Msrun::Nokogiri::NOBLANKS)
    msrun_n = doc.root 
    if @version >= '2.0'
      msrun_n = msrun_n.child
    end
    @msrun.scan_count = msrun_n['scanCount'].to_i
    @msrun.start_time = msrun_n['startTime'][2...-1].to_f
    @msrun.end_time = msrun_n['endTime'][2...-1].to_f

    filename = msrun_n.search("parentFile").first['fileName']
    (bn, dn) = Ms::Mzxml.parent_basename_and_dir(filename)
    @msrun.parent_basename = bn
    @msrun.parent_location = dn
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
  def peakdata_start_and_length(string)
    end_pos = string.rindex("</peaks>")
    start = string.rindex(">", end_pos) + 1
    [start, (end_pos - start)]
  end
  
  # assumes that the io object has been set to the beginning of the scan
  # element.  Returns an Ms::Scan object
  # options: 
  #     :spectrum => true | false (default is true)
  #     :precursor => true | false (default is true)
  def parse_scan(start_byte, length, options={})
    opts = {:spectrum => true}.merge(options)
    start_io_pos = @io.pos
    @io.pos = start_byte
    string = @io.read(length)
    doc = Nokogiri::XML.parse(string, nil, nil, Ms::Msrun::Nokogiri::NOBLANKS )
    scan_n = doc.root
    scan = new_scan_from_node( scan_n )
    prec_n = scan_n.child

    peaks_n = 
      if prec_n.name == 'precursorMz'
        if opts[:precursor]
          prec = Ms::Precursor.new
          prec[1] = prec_n['precursorIntensity'].to_f
          prec[0] = prec_n.text.to_f
          if x = prec_n['precursorCharge']
            prec[3] = [x.to_i]
          end
          scan.precursor = prec
        end
        prec_n.next_sibling
      else
        prec_n # this is a peaks node
      end
    raise RuntimeError, "expecting peaks node!" unless peaks_n.name == 'peaks'

    # is this for mzData?
    #if x = node['precursorScanNum']
    #  prec[2] = scans_by_num[x.to_i]
    #end
    
    if opts[:spectrum]
      (string_start, string_length) = peakdata_start_and_length(string)
      peaks_start_byte = start_io_pos + string_start

      data = Ms::Data::LazyIO.new(@io, peaks_start_byte, string_length, Ms::Data::LazyIO.unpack_code(peaks_n['precision'].to_i, NetworkOrder))
      scan[8] = Ms::Spectrum.new(Ms::Data::Interleaved.new(data))
    end
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


