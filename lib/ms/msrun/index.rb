require 'ms/msrun'
require 'andand'
require 'openany'

module Ms ; end
class Ms::Msrun ; end

# An Ms::Msrun::Index is merely an array of doublets, where each doublet is a
# start byte and a length.  It is always zero indexed, but it can be queried
# by specific id's.
#
#     Ms::Msrun::Index.new("file.mzXML")  # returns an Ms::Msrun::Index::Mz[x]ml object
#     index.ids # -> ["1", "2", "3" ... ]  # mzXML
#     index.ids # -> ["controllerType=0 controllerNumber=1 scan=1", ...]  # mzML
#     index.index_type # -> :scans | :spectra    (mzXML => :scans, mzML => :spectra)
#     index.each do |starting_byte, length|
#       IO.read(myfile.mzXML, length, starting_byte) # -> xml for each spectrum or scan
#     end
#     index[0]  => [start_byte, length]    of the first scan/spectrum
#     index[-1] => [start_byte, length]    of the last scan/spectrum
module Ms::Msrun::Index

  # an array of the id strings held in the index
  # for mzXML, this is the scan numb
  attr_accessor :ids


  # returns the length in bytes from the start to the first scan
  def header_length
    #self.each {|pair| return (pair.first) }
    self[0][0]
  end

  # returns a hash with id string keys and spectra/scans as values
  def index_by_id
    Hash[ ids.zip(self) ]
  end

  def get_by_id(id)
    self[ids.index(id)]
  end

  # for each item indexed, yields the id String and the [offset, length] array
  def id_with_each(&block)
    ids.zip(self, &block)
  end


  # returns an array of each id and an array of start bytes. Uses
  # regexpressions so it is very fast but could possibly break on weirdly
  # formatted xml.  If a name_re is passed in, it returns the index name
  def self.id_and_start_byte_arrays(xml_string, index_re, breaktag_re)
    ids = []
    indices = []
    xml_string.each_line("\n") do |line|
      if md = line.match(index_re)
        ids << md[1]
        indices << md[2].to_i
      elsif line.match(breaktag_re)
        break
      end
    end
    [ids, indices]
  end

  def index_offset_tag
    self.class.const_get('INDEX_TAG')
  end

  def index_ref_re
    self.class.const_get('INDEX_REF_RE')
  end

  # returns [index_offset, length_of_index]
  # the filesize will be queried File.size(io.path) if not provided by
  # filesize.  If filesize is nil, the stream will be scanned forwards for the
  # index.
  def self.index_offset(io, tag=MZML_INDEX_TAG, bytes_backwards=200, filesize=nil) # :nodoc:
    filesize = File.size(io.path) if filesize.nil?
    unless filesize == false
      io.pos = filesize-1 - bytes_backwards
    end
    tag_re = %r{<#{tag}>([\-\d]+)</#{tag}>}
    _index_offset = nil
    index_end = nil
    io.each do |line|
      if line =~ tag_re
        _index_offset = $1.to_i
        # the end of the index is assumed to be just before the
        # indexListOffset tag (or mzXML equiv)
        index_end = io.pos - line.size
        break
      end
    end
    if _index_offset
      [_index_offset, index_end - _index_offset]
    else
      [nil,nil]
    end
  end

  # non-destructive rewind: saves the position and returns it after the block
  # is executed. Returns the block's reply.
  def safe_io_rewind(io, &block)
    start = io.pos
    io.rewind
    reply = block.call 
    io.pos = start
    reply
  end

  # a list of index objects
  class List < Array

    # takes an mz[X]ML filename or io object
    # and returns an array of offsets and lengths for the scans
    def initialize(filename_or_io)
      (ft, version) = Ms::Msrun.filetype_and_version(filename_or_io)
      openany(filename_or_io) do |io|
        case ft
        when :mzxml
          self[0] = Ms::Msrun::Index::Mzxml.new(io)
        when :mzml
          set_from_file_io(io)
        end
      end
    end

    # returns boolean based on whether the mzML file has been indexed.
    # Implemented by looking for the indexedML tag in the first three lines of
    # the file. returns io to wherever it was when handed in.
    def has_index?(io)
      safe_io_rewind(io) do
        !!3.times.map { io.gets }.join.match(/<indexedmzML/m)
      end
    end

    attr_accessor :header_startbyte_and_length 

    def set_header_startbyte_and_length(io)
      start = nil
      _length = nil
      end_pos = nil
      openany(io) do |inner_io|
        io.rewind
        io.each_line("\n") do |line|
          if md = line.match(/<mzML /)
            start = io.pos - (line.bytesize - md.prematch.bytesize)
            break
          end
        end
        io.each_line("\n") do |line|
          if md = line.match(/<run /)
            end_pos = io.pos - (line.bytesize - md.prematch.bytesize)
            break
          end
        end
      end
      _length = end_pos - start if end_pos
      @header_startbyte_and_length = [start, _length]
    end

    # sets self with an array of index objects.  Currently, this should only
    # be run on an mzML file.  If no index is found, tries to create a
    # spectrum and/or a chromatogram index
    def set_from_file_io(io)
      if has_index?(io)
        (index_offset, length_of_index) = Ms::Msrun::Index.index_offset(io, Ms::Msrun::Index::Mzml::INDEX_TAG)
        doc = Nokogiri::XML.parse(io.read(length_of_index, index_offset), *Ms::Msrun::Nokogiri::PARSER_ARGS)
        index_list_node = doc.root
        indices = index_list_node.children.map do |index_node|
          _ids = []
          offsets = index_node.children.map do |offset_node|
            _ids << offset_node['idRef']
            offset_node.text.to_i
          end
          offset_pairs = offsets.push(index_offset).each_cons(2).map {|s,sp1| [s, sp1 - s] }
          mzml_index = Ms::Msrun::Index::Mzml.new(offset_pairs)
          mzml_index.name = index_node['name']
          mzml_index.ids = _ids
          mzml_index
        end
        self.replace(indices)
        self
      else
        safe_io_rewind(io) do |inner_io|
          spectrum_index = Ms::Msrun::Index::Mzml.new_from_indexless_io_by_regex(inner_io, :spectrum, Ms::Msrun::Index::Mzxml::SpectrumList_re, Ms::Msrun::Index::Mzxml::Spectrum_re, Ms::Msrun::Index::Mzxml::Spectrum_close_re)
          (last_spec_start, last_spec_length) = spectrum_index.last
          inner_io.seek(last_spec_start + last_spec_length)
          chromatogram_index = Ms::Msrun::Index::Mzml.new_from_indexless_io_by_regex(inner_io, :chromatogram, Ms::Msrun::Index::Mzxml::ChromatogramList_re, Ms::Msrun::Index::Mzxml::Chromatogram_re, Ms::Msrun::Index::Mzxml::Chromatogram_close_re)
        end
      end
      set_header_startbyte_and_length(io)
      self
    end

  end


  class Mzxml < Array
    include Ms::Msrun::Index

    INDEX_TAG = 'indexOffset'
    INDEX_REF_RE = %r{id="(\d+)".*>(\d+)</}

    # returns an array of the scan numbers as Integers
    attr_reader :scan_nums

    # returns :scan
    def name ; :scan end

    def initialize(filename_or_io=nil)
      if filename_or_io
        openany(filename_or_io) do |io|
          set_from_file_io(io)
        end
      end
    end

    # takes a scan number as string or integer and retrieves the start byte
    # and length doublet
    def scan(scan_number)
      get_by_id(scan_number.to_s)
    end

    # assumes io object is connected to a file so that "File.size(io.path)" is
    # valid.  sets the 'ids' attribute to be an array of id strings and replaces
    # self with a parallel array of doublets, where each doublet consists of a
    # start byte and length. returns self.
    def set_from_file_io(io)
      (index_start_byte_offset, length) = Ms::Msrun::Index.index_offset(io, index_offset_tag)
      xml_st = io.seek(index_start_byte_offset) && io.read(length)
      (@ids, start_bytes) = id_and_start_byte_arrays(xml_st, index_ref_re)
      doublets = start_bytes.push(index_start_byte_offset).each_cons(2).map {|s,sp1| [s, sp1 - s] }
      self.replace(doublets)
      self
    end

  end

  class Mzml < Array
    include Ms::Msrun::Index

    INDEX_TAG = 'indexListOffset'
    INDEX_REF_RE = %r{<offset\s+idRef="([^"]+)".*>(\d+)</}

    SpectrumList_re = %r{<spectrumList [^>]*count="(\d)+"}
    Spectrum_re = %r{<spectrum .*?id="[^"]+".*?>}
    Spectrum_close_re = %r{</spectrum>}

    ChromatogramList_re = %r{<chromatogramList [^>]*count="(\d)+"}
    Chromatogram_re = %r{<chromatogram .*?id="[^"]+".*?>}
    Chromatogram_close_re = %r{</chromatogram>}

    Scan_re = %r{scan=(\d+)}

    # reads the io and generates an Index object.
    # assumes the file is formatted with no more than one spectrum tag per line
    # will raise an error if this assumption is violated.
    # returns an Ms::Msrun::Index::Mzml object.  The io begins reading from
    # where it is at.  The index will be empty if nothing matches.
    def self.new_from_indexless_io_by_regex(io, name, start_re, index_it_re, close_re)
      _ids = []
      start_indices_plus_tail = []
      # find the spectrum list tag and see how many spectra there are
      cnt = 0
      while line = io.gets  
        if md = start_re.match(line)
          cnt = md[1].to_i
          break
        end
      end

      last_match_position = nil 
      while line = io.gets
        if md = index_it_re.match(line)
          start_indices_plus_tail.push( io.pos - (md.post_match.bytesize + md.to_s.bytesize) )
          _ids << md[1]
          last_match_position = io.pos
        end
      end

      io.pos = last_match_position
      while line = io.gets
        if md = close_re.match(line)
          start_indices_plus_tail.push( 1 + io.pos -  md.post_match.bytesize )
        end
        prev_pos = io.pos
      end
      doublets = start_indices_plus_tail.each_cons(2).map {|start, fin| [start, fin - start] }

      # this is a sanity check to ensure we parsed as many spectra out as we
      # had counts for at the beginning.  If not, something is messed up!
      raise RuntimeError, "bad index parse" if (_ids.size != cnt) || (doublets.size != cnt)
      index = Ms::Msrun::Index.new(doublets)
      index.name = name
      index.ids = _ids
      index
    end

    # the name of this type of index: :spectrum | :chromatogram
    attr_accessor :name

    # takes a scan number as string or integer and retrieves the start byte
    # and length doublet
    def scan(scan_number)
      si = @scan_index || create_scan_index 
      get_by_id(si[scan_number.to_i])
    end

    # a hash with integer scan number keys and an id as value.
    # This is created by calling create_scan_index and harvesting scans from
    # ids.  Scan numbers *may* collide, but the first scan with that number
    # will be used.  Use ids for guaranteed unique names.
    def scan_index
      @scan_index ||= create_scan_index
    end

    # returns true if there are duplicate scan numbers.  Creates the
    # scan_index if it doesn't already exist.
    def duplicate_scan_numbers?
      create_scan_index if @duplicate_scan_numbers.nil?
      @duplicate_scan_numbers
    end

    # returns @scan_index
    # uses the first scan with that index in case of collisions
    def create_scan_index(scan_re=Scan_re)
      @duplicate_scan_numbers = false
      @scan_index = {}
      ids.each do |id|
        index = id.match(scan_re).andand[1].to_i
        if @scan_index.key?(index)
          @duplicate_scan_numbers = true 
        else
          @scan_index[index] = id
        end
      end
      @scan_index
    end


  end
end

=begin

    fn = 
      if filename_or_io.is_a? String
        filename_or_io  # a filename
      else # a File object
        filename_or_io.path
      end
    size = File.size(fn)
    io =
      if filename_or_io.is_a? String
        File.open(filename_or_io)
      else
        filename_or_io
      end
    index_obj = 
      case ft
      when :mzml
      when :mzxml
      end
    io.close if filename_or_io.is_a?(String)
    index_obj
  end

    if has_index?(io, ft)
      self.replace(array)
    else
      # right now, the only filetype than can be without an index is mzML
      set_from_mzml(io)
    end
  end


=end
