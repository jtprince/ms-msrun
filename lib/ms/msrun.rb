
require 'ms/scan'
require 'ms/precursor'
require 'ms/spectrum'
require 'ms/msrun/search'
require 'ms/msrun/index'

module Ms; end

class Ms::Msrun
  include Enumerable

  #DEFAULT_PARSER = 'axml'
  #DEFAULT_PARSER = 'regexp'
  DEFAULT_PARSER = 'nokogiri'

  # the retention time in seconds of the first scan (regardless of any
  # meta-data written in the header)
  attr_accessor :start_time
  # the retention time in seconds of the last scan (regardless of any
  # meta-data written in the header)
  attr_accessor :end_time

  # The filetype. Valid types (for parsing) are:
  #   :mzxml
  #   :mzdata
  #   :mzml
  attr_accessor :filetype

  # the string passed in to open the file for reading
  attr_accessor :filename

  # The version string of this type of file
  attr_accessor :version
  # the total number of scans
  attr_writer :scan_count

  # The basename of the parent file listed (e.g., a .RAW file).  Note that in
  # v1 mzXML this will be *.mzXML while in later versions it's *.RAW.
  # See parent_basename_noext for more robust value
  attr_accessor :parent_basename

  # The location of the parent file (e.g., a .RAW file).  In version mzXML v1
  # this will be nil.
  attr_accessor :parent_location

  # an array of doublets, [start_byte, length] for each scan element
  attr_accessor :index

  # holds the class that parses the file
  attr_accessor :parser

  # an array holding the scan numbers found in the run
  attr_accessor :scan_nums

  # Opens the filename 
  def self.open(filename, &block)
    File.open(filename) {|io| block.call( self.new(io, filename) ) }
  end

  # takes an io object.  The preferred way to access Msrun objects is through
  # the open method since it ensures that the io object will be available for
  # the lazy evaluation of spectra.
  def initialize(io, filename=nil)
    @scan_counts = nil
    @filename = filename
    @filetype, @version = Ms::Msrun.filetype_and_version(io)
    parser_klass = Ms::Msrun.get_parser(@filetype, @version)

    @parser = parser_klass.new(self, io, @version)
    @index = Ms::Msrun::Index.new(io)
    @scan_nums = @index.scan_nums
    @parser.parse_header(@index.header_length)
  end

  def parent_basename_noext
    @parent_basename.chomp(File.extname(@parent_basename))
  end

  # returns each scan
  # options:
  #     :spectrum => true | false (default is true)
  #     :precursor => true | false (default is true)
  #     :ms_level => Integer or Array return only scans of that level
  #     :reverse => true | false (default is false) goes backwards
  def each_scan(parse_opts={}, &block)
    ms_levels = 
      if msl = parse_opts[:ms_level]
        if msl.is_a?(Integer) ; [msl]
        else ; msl  
        end
      end
    snums = @index.scan_nums
    snums = snums.reverse if parse_opts[:reverse]
    snums.each do |scan_num|
      if ms_levels
        next unless ms_levels.include?(ms_level(scan_num))
      end
      block.call(scan(scan_num, parse_opts))
    end
  end
  alias_method :each, :each_scan

  # opens the file and yields each scan in the block
  # see each_scan for parsing options
  def self.foreach(filename, parse_opts={}, &block)
    self.open(filename) do |obj|
      obj.each_scan(parse_opts, &block)
    end
  end

  # a very fast method to only query the ms_level of a scan
  def ms_level(num)
    @parser.parse_ms_level(@index[num].first, @index[num].last)
  end

  # returns a Ms::Scan object for the scan at that number
  #
  def scan(num, parse_opts={})
    #@parser.parse_scan(*(@index[num]), parse_opts)
    @parser.parse_scan(@index[num].first, @index[num].last, parse_opts)
  end

  #bracket_method = '[]'.to_sym
  #alias_method bracket_method, :scan

  # returns an array, whose indices provide the number of scans in each index level the ms_levels, [0] = all the scans, [1] = mslevel 1, [2] = mslevel 2,
  # ...
  def scan_counts
    return @scan_counts if @scan_counts
    ar = []
    ar[0] = 0
    each_scan do |sc|Modes of inference for evaluating the confidence of Peptide identifications
      level = sc.ms_level
      unless ar[level]
        ar[level] = 0
      end
      ar[level] += 1
      ar[0] += 1
    end
    @scan_counts = ar
  end

  def scan_count(mslevel=0)
    if @scan_counts
      @scan_counts[mslevel]
    else
      if mslevel == 0
        @scan_count 
      else
        scan_counts[mslevel]
      end
    end
  end


  # returns [start_mz, end_mz] for ms level 1 scans or [nil,nil] if unknown
  def start_and_end_mz
    scan = first(:ms_level => 1, :spectrum => false, :precursor => false)
    [scan.start_mz, scan.end_mz]
  end

  # goes through every scan and gets the first and last m/z, then returns the
  # max.ceil and min.floor
  def start_and_end_mz_brute_force
    first_scan = first(:ms_level => 1, :precursor => false)
    first_mzs = first_scan.spectrum.mzs

    lo_mz = first_mzs[0]
    hi_mz = first_mzs[-1]

    each_scan(:ms_level => 1, :precursor => false) do |sc|
      mz_ar = sc.spectrum.mzs
      if mz_ar.last > hi_mz
        hi_mz = mz_ar.last
      end
      if mz_ar.last < lo_mz
        lo_mz = mz_ar.last
      end
    end
    [lo_mz.floor, hi_mz.ceil]
  end

  def first(opts={})
    the_first = nil
    each_scan(opts) do |scan|
      the_first = scan
      break
    end
    the_first
  end

  def last(opts={})
    opts[:reverse] = true
    first(opts)
  end

  def self.get_parser(filetype, version)
    require "ms/msrun/#{DEFAULT_PARSER}/#{filetype}"
    parser_class = filetype.to_s.capitalize
    base_class = Ms::Msrun.const_get( DEFAULT_PARSER.capitalize )
    if base_class.const_defined? parser_class
      base_class.const_get parser_class
    else
      raise RuntimeError, "no class #{base_class}::#{parser_class}"
    end
  end

  # only adds the parent if one is not already present!
  def self.add_parent_scan(scans, add_intensities=false)
    prev_scan = nil
    parent_stack = [nil]
    ## we want to set the level to be the first mslevel we come to
    prev_level = scans.first.ms_level
    scans.each do |scan|
      #next unless scan  ## the first one is nil, (others?)
      level = scan.ms_level
      if prev_level < level
        parent_stack.unshift prev_scan
      end
      if prev_level > level
        (prev_level - level).times do parent_stack.shift end
      end
      if scan.ms_level > 1
        precursor = scan.precursor
        #precursor.parent = parent_stack.first  # that's the next line's
        precursor[2] = parent_stack.first unless precursor[2]
        #precursor.intensity
        if add_intensities
          precursor[1] = precursor[2].spectrum.intensity_at_mz(precursor[0])
        end
      end
      prev_level = level
      prev_scan = scan
    end
  end


  Mzxml_regexp = /http:\/\/sashimi.sourceforge.net\/schema(_revision)?\/([\w\d_\.]+)/o
  # 'http://sashimi.sourceforge.net/schema/MsXML.xsd' # version 1
  # 'http://sashimi.sourceforge.net/schema_revision/mzXML_X.X' # others
  Mzdata_regexp = /<mzData.*version="([\d\.]+)"/m
  Raw_header_unpack_code = '@2axaxaxaxaxaxaxa'
  Mzml_regexp = /http:\/\/psidev.info\/files\/ms\/mzML\/xsd\/mzML([\w\d_\.]+)_idx.xsd/o

  def self.filetype_and_version(file_or_io)
    if file_or_io.is_a? IO
      io = file_or_io
      found = nil
      io.rewind
      # Test for RAW file:
      header = io.read(18).unpack(Raw_header_unpack_code).join
      if header == 'Finnigan'
        return [:raw, nil]
      end
      io.rewind
      while (line = io.gets)
        found = 
          case line
          when Mzml_regexp
            [:mzml, $1.dup]
          when Mzxml_regexp
            mtch = $2.dup
            case mtch
            when /mzXML_([\d\.]+)/
              [:mzxml, $1.dup]
            when /MsXML/
              [:mzxml, '1.0']
            else
              abort "Cannot determine mzXML version!"
            end
          when Mzdata_regexp
            [:mzdata, $1.dup]
          end
        if found
          break
        end
      end
      io.rewind
      found
    else
      File.open(file_or_io) do |_io|
        filetype_and_version(_io)
      end
    end
  end

end
