require 'ms/scan'
require 'ms/precursor'
require 'ms/spectrum'
require 'ms/msrun/search'
require 'ms/msrun/index'
require 'openany'

module Ms; end
class Ms::Spectrum
  attr_accessor :scans
end

module Ms; end
  module Ms::Msrun
    include Enumerable

    # the string passed in to open the file for reading
    attr_accessor :filename

    # The version string for this type of file (i.e., for mzXML version 2.1,
    # version would be: '2.1')
    attr_accessor :version

    # an array holding index objects.  Each index object is an an array of
    # doublets, [start_byte, length] for each indexed element (spectra,
    # chromatograms, scans, or whatever).  mzXML has a single index list (the
    # scan list) while mzML will typically have a spectra list and chromatogram
    # list.
    attr_accessor :index_list

    # the files that preceded the one you are working with
    attr_accessor :sourcefiles

    # holds the class that parses the file
    attr_accessor :parser

    # Opens the filename 
    def self.open(filename, &block)
      File.open(filename) {|io| block.call( self.new(io) ) }
    end

    # retrieves the first index object
    def index ; @index_list.first end
    # sets the first index
    def index=(val) ; @index_list[0] = val end
    # retrieves the value of the first sourcefile
    def sourcefile ; sourcefiles[0] end
    # sets the value of the first sourcefile
    def sourcefile=(val) ; sourcefiles[0] = val end


    def self.new(io, filename=nil, io_size=nil)
      (ft, version) = filetype_and_version(io)
      obj = Ms::Msrun.const_get(ft.to_s.capitalize).new(io) 
      obj.version = version
      obj
    end

    # :mzxml or :mzml based on the class of the object
    def filetype
      self.class.to_s.split('::').to_sym
    end

    # takes an io object.  The preferred way to access Msrun objects is through
    # the open method since it ensures that the io object will be available for
    # the lazy evaluation of spectra.  If you are passing in an IO object that
    # doesn't respond to path for retrieval of the size, you should pass it in
    # as it will speed up lots of methods that need to seek to the end of the io
    # stream.
    def initialize(io, filename=nil, io_size=nil)
      @filename = filename || ( io.respond_to?(:path) ? io.path : nil )
      @io_size = io_size || File.size(@filename)
      @sourcefiles = []
      @index_list = Ms::Msrun::Index.index_list(io)
      parser_klass = Ms::Msrun.get_parser(@filetype, @version)
      @parser = parser_klass.new(self, io)
      @parser.parse_header(index.header_startbyte_and_length)
    end


    def each_spectrum(parse_opts={}, &block)
      raise NotImplementedError, "the subclass ought to implement me"
    end

    alias_method :each, :each_spectrum

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
      snums = index.scan_nums
      snums = snums.reverse if parse_opts[:reverse]
      snums.each do |scan_num|
        if ms_levels
          next unless ms_levels.include?(get_ms_level(scan_num))
        end
        block.call(scan(scan_num, parse_opts))
      end
    end

    # opens the file and yields each spectrum in the block
    # see each_scan for parsing options
    def self.foreach(filename, parse_opts={}, &block)
      self.open(filename) do |obj|
        obj.each(parse_opts, &block)
      end
    end

    # fast method to only query the ms_level of a scan/spectrum.  Access
    def get_ms_level(idstring)
      @parser.parse_ms_level(*index.get_by_id(idstring))
    end

    # returns a Ms::Scan object for the scan at that number
    #
    def scan(num, parse_opts={})
      i = index.scan(num)
      @parser.parse_scan(i[0], i[1], parse_opts)
    end

    # returns an array, whose indices provide the number of scans in each index level the ms_levels, [0] = all the scans, [1] = mslevel 1, [2] = mslevel 2,
    def scan_counts
      return @scan_counts if @scan_counts
      ar = []
      ar[0] = 0
      each_scan do |sc|
        level = sc.get_ms_level
        unless ar[level]
          ar[level] = 0
        end
        ar[level] += 1
        ar[0] += 1
      end
      @scan_counts = ar
    end

    # returns an array, whose indices provide the number of spectrum in each index level the ms_levels, [0] = all the scans, [1] = mslevel 1, [2] = mslevel 2,
    def spectrum_counts
      raise NotImplementedError
    end

    # returns the number of scans at that ms level.  returns total scan count if
    # given 0
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

    # returns the number of spectra at that ms level.  returns total spectrum
    # count if given 0
    def spectrum_count(mslevel=0)
      raise NotImplementedError
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

    # takes normal filter options
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


    Mzxml_regexp = %r{http://sashimi.sourceforge.net/schema(_revision)?/([\w\d_\.]+)}
    # 'http://sashimi.sourceforge.net/schema/MsXML.xsd' # version 1
    # 'http://sashimi.sourceforge.net/schema_revision/mzXML_X.X' # others
    Mzdata_regexp = /<mzData.*version="([\d\.]+)"/m
    Raw_header_unpack_code = '@2axaxaxaxaxaxaxa'
    Mzml_regexp = /http:\/\/psidev.info\/files\/ms\/mzML\/xsd\/mzML([\d\.]+)(_idx)?.xsd/o

    # returns :mzml, :mzxml, or :mzdata or nil
    def self.filetype(file_or_io)
      filetype_and_version(file_or_io).first
    end

    # returns :mzml, :mzxml, or :mzdata and a version string
    def self.filetype_and_version(file_or_io)
      openany(file_or_io) do |io|
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
      end
    end

  end
