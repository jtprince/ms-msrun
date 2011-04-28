require 'ms/scan'
require 'ms/precursor'
require 'ms/spectrum'
require 'ms/msrun/search'
require 'ms/msrun/index'
require 'ms/msrun/mzml'
require 'ms/msrun/mzxml'
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
    # scan list) while mzML will typically have a spectra list and possibly a
    # chromatogram list.
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

    # opens the file and yields each spectrum in the block
    # see each_spectrum for parsing options
    def self.foreach(filename, parse_opts={}, &block)
      self.open(filename) do |obj|
        obj.each(parse_opts, &block)
      end
    end

    # fast method to only query the ms_level of a scan/spectrum.
    def get_ms_level(idstring)
      @parser.parse_ms_level(*index.get_by_id(idstring))
    end

    # returns the number of spectra associated with the first spectrum index.
    def spectrum_count
      spec_index = @indices.find {|i| i.name==:spectrum }
      spec_index.nil? ? 0 : spec_index.size
    end

    # returns an array whose indices provide the number of objects in each
    # index level.  type may be :spectrum (default) or :scan
    #
    #     ms_levels[0] = all the objects
    #     ms_levels[1] = mslevel 1
    #     ms_levels[2] = mslevel 2
    #     # ... and so on.
    #
    # ms_levels is only calculated once and the result saved in @ms_levels.
    # Sets @ms_levels if it is calculated.
    def ms_levels(type=:spectrum)
      ms_levels_type = instance_variable_get("@ms_levels_#{type}".to_sym)
      return ms_levels_type if ms_levels_type
      ar = []
      ar[0] = 0
      self.send("each_#{type}".to_sym, :spectrum=>false, :precursor=>false) do |obj|
        level = obj.ms_level
        ar[level] ||= 0
        ar[level] += 1
        ar[0] += 1
      end
      instance_variable_set("@ms_levels_#{type}".to_sym, ar)
    end

    # takes normal filter options
    def first(opts={})
      each_spectrum(opts) do |spectrum|
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
      require "ms/msrun/#{filetype}/parser"
      parser_class = filetype.to_s.capitalize
      base_class = Ms::Msrun.const_get( DEFAULT_PARSER.capitalize )
      if base_class.const_defined? parser_class
        base_class.const_get parser_class
      else
        raise RuntimeError, "no class #{base_class}::#{parser_class}"
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
                raise "Cannot determine mzXML version!"
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



=begin

# goes through every scan and gets the first and last m/z, then returns the
# max.ceil and min.floor
def start_and_end_mz_brute_force(ms_level=1)
  first_scan = first(:ms_level => ms_level, :precursor => false)
  first_mzs = first_scan.spectrum.mzs

  lo_mz = first_mzs[0]
  hi_mz = first_mzs[-1]

  each_spectrum(:ms_level => ms_level, :precursor => false) do |sc|
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
=end

