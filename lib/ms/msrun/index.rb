require 'ms/msrun'
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

  # takes an mz[X]ML filename or io object
  # and returns an array of offsets and lengths for the scans
  # note that the offset 
  def self.new(filename_or_io=nil)
    if filename_or_io
      (ft, version) = Ms::Msrun.filetype_and_version(filename_or_io)
      Ms::Msrun::Index.const_get(ft.to_s.capitalize).new
    end
  end

  # returns the length in bytes from the start to the first scan
  def header_length
    #self.each {|pair| return (pair.first) }
    self[0][0]
  end

  # for each item indexed, yields the id String and the [offset, length] array
  def id_with_each(&block)
    ids.zip(self, &block)
  end

  # assumes io object is connected to a file so that "File.size(io.path)" is
  # valid.  sets the 'ids' attribute to be an array of id strings and replaces
  # self with a parallel array of doublets, where each doublet consists of a
  # start byte and length. returns self.
  def set_from_file_io(io)
    (offset, length) = Ms::Msrun::Index.index_offset(io, index_offset_tag)
    xml_st = io.seek(offset) && io.read(length)
    index_to_array(xml_st, offset, index_ref_re)
    (_ids, start_bytes) = id_and_start_byte_arrays(xml_st, index_ref_re)
    doublets = start_bytes.push(last_offset).each_cons(2).map {|s,sp1| [s, sp1 - s] }
    ids = _ids
    self.replace(doublets)
    self
  end

  # returns an array of each id and an array of start bytes
  def id_and_start_byte_arrays(xml_string, index_re)
    ids = []
    indices = []
    xml_string.each_line("\n") do |line|
      if md = line.match(index_re)
        ids << md[1]
        indices << md[2].to_i
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
  # filesize.
  def self.index_offset(io, tag=MZML_INDEX_TAG, bytes_backwards=200, filesize=nil) # :nodoc:
    filesize ||= File.size(io.path)
    tag_re = %r{<#{tag}>([\-\d]+)</#{tag}>}
      io.pos = filesize-1
    io.pos = io.pos - bytes_backwards
    _index_offset = nil
    index_end = nil
    io.each do |line|
      if line =~ tag_re
        _index_offset = $1.to_i
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

  class Mzxml < Array
    include Ms::Msrun::Index

    INDEX_TAG = 'indexOffset'
    INDEX_REF_RE = %r{id="(\d+)".*>(\d+)</}

    # returns an array of the scan numbers as Integers
    attr_reader :scan_nums

    def initialize(filename_or_io=nil)
      if filename_or_io
        openany(filename_or_io) do |io|
          set_from_file_io(io)
        end
      end
    end
  end

  class Mzml < Array
    include Ms::Msrun::Index

    INDEX_TAG = 'indexListOffset'
    INDEX_REF_RE = %r{<offset\s+idRef="([^"]+)".*>(\d+)</}

    SpectrumList_re = /<spectrumList [^>]*count="(\d)+"/
      # right now, this is flaky because a scan number may not be unique
      Spectrum_re = /<spectrum .*?id="[^"]+".*?>/
      Spectrum_close_re = %r{</spectrum>}

    def initialize(filename_or_io=nil)
      if filename_or_io
        openany do |io|
          if has_index?
            set_from_file_io(io)
          else
            set_from_indexless_io(io)
          end
        end
      end
    end

    # reads the io and generates an Index object.
    # assumes the file is formatted with no more than one spectrum tag per line
    # will raise an error if this assumption is violated.
    # returns self
    def set_from_indexless_io(io)
      _ids = []
      safe_io_rewind(io) do
        start_indices_plus_tail = []
        # find the spectrum list tag and see how many spectra there are
        cnt = nil
        while line = io.gets  
          if md = SpectrumList_re.match(line)
            cnt = md[1].to_i
            break
          end
        end

        last_match_position = nil 
        while line = io.gets
          if md = Spectrum_re.match(line)
            start_indices_plus_tail.push( io.pos - (md.post_match.bytesize + md.to_s.bytesize) )
            _ids << md[1]
            last_match_position = io.pos
          end
        end

        io.pos = last_match_position
        while line = io.gets
          if md = Spectrum_close_re.match(line)
            start_indices_plus_tail.push( 1 + io.pos -  md.post_match.bytesize )
          end
          prev_pos = io.pos
        end
        doublets = start_indices_plus_tail.each_cons(2).map {|start, fin| [start, fin - start] }

        # this is a sanity check to ensure we parsed as many spectra out as we
        # had counts for at the beginning.  If not, something is messed up!
        raise RuntimeError, "bad index parse" if (_ids.size != cnt) || (doublets.size != cnt)
        ids = _ids
        self.replace(doublets)
        self
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
