
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

  # returns the ms_level as an Integer, nil if it cannot be found.
  def parse_ms_level(start_byte, length)
    start_io_pos = @io.pos
    @io.pos = start_byte
    ms_level = nil
    total_length = 0
    @io.each("\n") do |line|
      if line =~ /msLevel="(\d+)"/o
        ms_level = $1.to_i
        break
      end
      total_length += line.size
      break if total_length > length
    end
    @io.pos = start_io_pos
    ms_level
  end

  # assumes that the io object has been set to the beginning of the scan
  # element.  Returns an Ms::Scan object
  # options: 
  #     :spectrum => true | false (default is true)
  #     :precursor => true | false (default is true)
  #
  # Note that if both :spectrum and :precursor are set to false, the basic
  # information in the scan node *is* parsed (such as ms_level)
  def parse_scan(start_byte, length, options={})
    opts = {:spectrum => true, :precursor => true}.merge(options)
    start_io_pos = @io.pos
    @io.pos = start_byte

    # read in the data keeping track of peaks start and stop
    string = ""
    if opts[:spectrum]
      string = @io.read(length)
    else
      # don't bother reading all the peak information if we aren't wanting it
      # and can avoid it!  This is important for high res instruments
      # especially since the peak data is huge.
      @io.each do |line|
        if md = %r{<peaks}.match(line)
          # just add the part of the string before the <peaks> tag
          string << line.slice!(0, md.end(0) - 6)
          break
        else
          string << line
          if string.size >= length
            if string.size > length
              string.slice!(0,length)
            end
            break
          end
        end
      end
    end
        
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
      # all mzXML (at least versions 1--3.0) *must* be 'network' byte order!
      # data is stored as the base64 string until we actually try to access
      # it!  At that point the string is decoded and knows it is interleaved
      # data.  So, no spectrum is actually decoded unless it is accessed!
      peaks_data = Ms::Data.new_interleaved(Ms::Data::LazyString.new(peaks_n.text, Ms::Data::LazyIO.unpack_code(peaks_n['precision'].to_i, NetworkOrder)))
      spec = Ms::Spectrum.new(peaks_data)
      scan[8] = Ms::Spectrum.new(peaks_data)
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


