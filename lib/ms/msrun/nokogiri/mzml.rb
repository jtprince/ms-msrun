require 'nokogiri'
require 'ms/msrun/nokogiri'
require 'ms/msrun'
require 'ms/spectrum'
require 'ms/data'
require 'ms/data/lazy_io'
require 'ms/precursor'
require 'ms/mzxml'

class Ms::Msrun::Nokogiri::Mzml
  NetworkOrder = false
  
  attr_accessor :msrun, :io, :version
  
  def initialize(msrun_object, io, version)
    @msrun = msrun_object
    @io = io
    @version = version
  end
  
  # returns the msrun
  def parse_header(startbyte_and_header_length_or_string)
    string = 
      if startbyte_and_header_length_or_string.is_a? Array
        @io.pos = startbyte_and_header_length_or_string[0]
        @io.read(startbyte_and_header_length_or_string[1])
      else
        length_or_header_string
      end
    
    doc = Nokogiri::XML.parse(string, *Ms::Msrun::Nokogiri::PARSER_ARGS)
    msrun_n = doc.root 
    
    @msrun.scan_count = msrun_n.xpath("//xmlns:spectrumList/@count").to_s.to_i
    @msrun.start_time = msrun_n.xpath("//xmlns:run/@startTimeStamp").to_s
    @msrun.start_time = nil if @msrun.start_time == ""
    #@msrun.end_time = msrun_n['endTime'][2...-1].to_f  #There doesn't appear to be an endTime
    filename_pieces = msrun_n.xpath("//xmlns:sourceFile/@name").to_s.split(/[\/\\]/)
    @msrun.parent_basename = filename_pieces.last
    @msrun.parent_location = msrun_n.xpath("//xmlns:sourceFile/@location").to_s
    @msrun
  end
  
  # returns the ms_level as an Integer, nil if it cannot be found.
  def parse_ms_level(start_byte, length)
    start_io_pos = @io.pos
    @io.pos = start_byte
    ms_level = nil
    total_length = 0
    @io.each("\n") do |line|
      if line =~ /ms level" value="(\d+)"/o
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
        if md = %r{<binary>}.match(line)
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
    
    doc = Nokogiri::XML.parse(string, *Ms::Msrun::Nokogiri::PARSER_ARGS)
    scan_n = doc.root
    scan = new_scan_from_node(scan_n)
    prec_n = scan_n.xpath(".//precursorList")
    
    peaks_n = 
      if !prec_n.xpath(".//selectedIon").empty?
        if opts[:precursor]
          prec = Ms::Precursor.new
          prec[1] = prec_n.xpath(".//cvParam[@name=\"peak intensity\"]/@value").to_s.to_f
          prec[0] = prec_n.xpath(".//cvParam[@name=\"selected ion m/z\"]/@value").to_s.to_f
          charge = prec_n.xpath(".//cvParam[@name=\"charge state\"]/@value").to_s.to_i
          
          if charge > 0
            prec[3] = [charge]
          end
          
          scan.precursor = prec
        end
        scan_n.xpath(".//binaryDataArrayList")
      else
        scan_n.xpath(".//binaryDataArrayList")
      end
    
    if opts[:spectrum]
      # make sure packing order (Network Order is correct) and precision is correct
      mzArray = peaks_n.xpath(".//binaryDataArray[.//cvParam/@name=\"m/z array\"]")
      intensityArray = peaks_n.xpath(".//binaryDataArray[.//cvParam/@name=\"intensity array\"]")
      
      mzs = lazilyGetString(mzArray)
      intensities = lazilyGetString(intensityArray)
      spec = Ms::Spectrum.new(Ms::Data::new_simple([mzs, intensities]))  # Ms::Data
      
      scan[8] = spec
    end
    
    scan
  end
  
  def lazilyGetString(binaryDataArray)
    unpackFormat = Ms::Data::LazyIO.unpack_code(precision(binaryDataArray), Ms::Msrun::Nokogiri::Mzml::NetworkOrder)
    compression = false
    compression = true if binaryDataArray.xpath(".//cvParam[@name=\"no compression\"]").empty?
    Ms::Data::LazyString.new(binaryDataArray.text, unpackFormat, compression)
  end
  
  def precision(peaks_n)
    return 64 unless peaks_n.xpath(".//cvParam[@name=\"64-bit float\"]").empty?
    return 32 unless peaks_n.xpath(".//cvParam[@name=\"32-bit float\"]").empty?
  end
  
  def start_end_from_filter_line(line)
    # "ITMS + c NSI d Full ms3 654.79@cid35.00 630.24@cid35.00 [160.00-1275.00]"
    /\[([^-]+)-([^-]+)\]/.match(line)[1,2].map {|v| v.to_f}
  end
  
  def new_scan_from_node(node)
    scan = Ms::Scan.new  # array class creates one with 9 positions
    scan[0] = $1.to_i if node['id'] =~ /scan=(\d+)/
    scan[1] = node.xpath(".//cvParam[@name=\"ms level\"]/@value").to_s.to_i
    
    if x = node['retentionTime']  #I don't see such a value in the mzML file
      scan[2] = x[2...-1].to_f
    end
    
    if x = node['startMz']  #Or this
      scan[3] = x.to_f
      scan[4] = node['endMz'].to_f
    end
    
    scan[5] = node['defaultArrayLength'].to_i
    scan[6] = node.xpath(".//cvParam[@name=\"total ion current\"]/@value").to_s.to_f
    
    if fl = node['filterLine']
      (scan[3], scan[4]) = start_end_from_filter_line(fl)
    end
    
    scan
  end
end
