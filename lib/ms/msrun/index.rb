require 'andand'
require 'openany'

require 'ms/msrun'

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
    
  # the kind of index this is.  Typically :scan for mzXML and :spectrum or
  # :chromatogram for mzML
  attr_accessor :name

  def self.index_list(file_or_io)
    ft = Ms::Msrun.filetype(file_or_io)
    require "ms/msrun/index/#{ft}"
    self.const_get(ft.to_s.capitalize).index_list(file_or_io)
  end

  # returns a hash with id string keys and spectra/scans as values
  def index_by_id
    Hash[ ids.zip(self) ]
  end

  # retrieve scan by id.  This method currently does a linear scan through the
  # ids to find the index.  Use index_by_id to create hash index
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
  def self.id_and_start_byte_arrays(xml_string, index_re, breaktag_re=nil)
    ids = []
    indices = []
    xml_string.each_line("\n") do |line|
      if md = line.match(index_re)
        ids << md[1]
        indices << md[2].to_i
      elsif breaktag_re.andand.match(line)
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
end

