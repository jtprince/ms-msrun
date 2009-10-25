
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
    @parser.parse_header(@index.header_length)
    @scan_counts = nil  # <- to keep warnings away
  end

  def parent_basename_noext
    @parent_basename.chomp(File.extname(@parent_basename))
  end

  # returns each scan
  # options:
  #     :spectrum => true | false (default is true)
  #     :precursor => true | false (default is true)
  #     :ms_level => Integer or Array return only scans of that level
  def each_scan(parse_opts={}, &block)
    ms_levels = 
      if msl = parse_opts[:ms_level]
        if msl.is_a?(Integer) ; [msl]
        else ; msl  
        end
      end
    @index.scan_nums.each do |scan_num|
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
    scans.each do |sc|
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
        num = 0
        scans.each do |sc|
          if sc.ms_level == mslevel
            num += 1
          end
        end
        num
      end
    end
  end

  # for level 1, finds first scan and asks if it has start_mz/end_mz
  # attributes.  for other levels, asks for start_mz/ end_mz and takes the
  # min/max.  If start_mz and end_mz are not found, goes through every scan
  # finding the max/min first and last m/z. returns [start_mz (rounded down to
  # nearest int), end_mz (rounded up to nearest int)]
  def start_and_end_mz(mslevel=1)
    if mslevel == 1
      # special case for mslevel 1 (where we expect scans to be same length)
      scans.each do |sc|
        if sc.ms_level == mslevel
          if sc.start_mz && sc.end_mz
            return [sc.start_mz, sc.end_mz]
          end
          break
        end
      end
    end
    hi_mz = nil
    lo_mz = nil
    # see if we have start_mz and end_mz for the level we want
    # set the initial hi_mz and lo_mz in any case
    have_start_end_mz = false
    scans.each do |sc|
      if sc.ms_level == mslevel
        if sc.start_mz && sc.end_mz
          lo_mz = sc.start_mz
          hi_mz = sc.end_mz
        else
          mz_ar = sc.spectrum.mzs
          hi_mz = mz_ar.last
          lo_mz = mz_ar.first
        end
        break
      end
    end
    if have_start_end_mz
      scans.each do |sc|
        if sc.ms_level == mslevel
          if sc.start_mz < lo_mz
            lo_mz = sc.start_mz
          end
          if sc.end_mz > hi_mz
            hi_mz = sc.end_mz
          end
        end
      end
    else
      # didn't have the attributes (find by brute force)
      scans.each do |sc|
        if sc.ms_level == mslevel
          mz_ar = sc.spectrum.mzs
          if mz_ar.last > hi_mz
            hi_mz = mz_ar.last
          end
          if mz_ar.last < lo_mz
            lo_mz = mz_ar.last
          end
        end
      end
    end
    [lo_mz.floor, hi_mz.ceil]
  end

  # returns an array of times and parallel array of spectra objects.
  # ms_level = 0  then all spectra and times
  # ms_level = 1 then all spectra of ms_level 1
  def times_and_spectra(ms_level=0)
    spectra = []
    if ms_level == 0
      times = @scans.map do |scan|
        spectra << scan.spectrum  
        scan.time
      end
      [times, spectra]
    else  # choose a particular ms_level
      times = []
      @scans.each do |scan|
        if ms_level == scan.ms_level
          spectra << scan.spectrum  
          times << scan.time
        end
      end
      [times, spectra]
    end
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
  Mzml_regexp = /http:\/\/psi.hupo.org\/schema_revision\/mzML_([\w\d\.]+)/o

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
      File.open(file_or_io) do |io|
        filetype_and_version(io)
      end
    end
  end

end
