require 'ms/msrun'

module Ms ; end
class Ms::Msrun ; end

# an index by scan number of the doublets where each doublet = [start_byte,
# length] for the scan.  Index objects are enumerable and yield doublets.
# Index#scan_nums gives an array of the scan numbers.
# Index#first and Index#last return the first and the last scan, regardless of
# the scan numbers.
#
#     index.scan_nums  # -> [1,2,3,4]
#     index.each do |starting_byte, length|
#       IO.read(myfile.mzXML, length, starting_byte) # -> xml for each scan
#     end
#     index[0]         # -> nil
#     index.first      # -> [<start_byte>, <length>] # for scan number 1 
class Ms::Msrun::Index < Array
  include Enumerable

  MZXML_INDEX_TAG = 'indexOffset'
  MZML_INDEX_TAG = 'indexListOffset'

  # returns the length from the start to the first scan
  def header_length
    self.each {|pair| return (pair.first) }
  end

  # returns an array of the scan numbers
  attr_reader :scan_nums

  # takes an mz[X]ML filename or io object
  # and returns an array of offsets and lengths for the scans
  # note that the offset 
  def initialize(filename_or_io)
    (ft, version) = Ms::Msrun.filetype_and_version(filename_or_io)
    tag = case ft
          when :mzml ; MZML_INDEX_TAG
          when :mzxml ; MZXML_INDEX_TAG
          end
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
    if has_index?(io, ft)
      (offset, length) = index_offset(io, size, tag)
      io.pos = offset
      xml = io.read(length)
      io.close if filename_or_io.is_a?(String)
      array = index_to_array(xml, offset, ft)
      self.replace(array)
    else
      # right now, the only filetype than can be without an index is mzML
      set_from_mzml(io)
    end
  end

  SpectrumList_re = /<spectrumList [^>]*count="(\d)+"/o
  # right now, this is flaky because a scan number may not be unique
  Spectrum_re = /<spectrum .*?scan=(\d+).*?>/o
  Spectrum_close_re = /<\/spectrum>/o

  # TODO: NEED TO SORT OUT:
  # this is sort of a hack to fit mzML onto mzXML style indexer.
  # need to decide if mzML should use scan index as the index in (but it is a
  # zero indexed guy) or the scan id (meaning it would not be an integer, so
  # the object would need to be completely different).

  # reads the io and generates an Index object.
  # assumes the file is formatted with no more than one spectrum tag per line
  # will raise an error if this assumption is violated.
  # returns self
  def set_from_mzml(io)
    @scan_nums = []
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
          @scan_nums << Integer(md[1])
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
      start_indices_plus_tail.each_cons(2).zip(@scan_nums) do |start_fin, scan_num|
        (start, fin) = start_fin
        self[scan_num] = [start, fin - start]
      end

      # this is a sanity check to ensure we parsed as many spectra out as we
      # had counts for at the beginning.  If not, we messed up.
      raise RuntimeError, "bad index parse" if @scan_nums.size != cnt
      self
    end
  end

  def has_index?(io, filetype)
    case filetype
    when :mzxml ; true
    when :mzml ; mzml_has_index?(io)
    end
  end

  # returns boolean based on whether the mzML file has been indexed.
  # Implemented by looking for the indexedML tag in the first three lines of
  # the file. returns io to wherever it was when handed in.
  def mzml_has_index?(io)
    safe_io_rewind(io) do
      !!3.times.map { io.gets }.join.match(/<indexedmzML/m)
    end
  end

  def each(&block)
    scan_nums.each do |scan_num|
      block.call( self[scan_num] )
    end
  end

  def first
    self[scan_nums.first]
  end

  def last
    self[scan_nums.last]
  end

  # returns [index_offset, length_of_index]
  def index_offset(io, size, tag=MZML_INDEX_TAG, bytes_backwards=150) # :nodoc:
    tag_re = /<#{tag}>([\-\d]+)<\/#{tag}>/
      io.pos = size-1
    io.pos = io.pos - bytes_backwards
    index_offset = nil
    index_end = nil
    io.each do |line|
      if line =~ tag_re
        index_offset = $1.to_i
        index_end = io.pos - line.size
        break
      end
    end
    if index_offset
      [index_offset, index_end - index_offset]
    else
      [nil,nil]
    end
  end

  # last_offset is used to calculate the length of the last scan object (or
  # whatever)
  def index_to_array(xml_string, last_offset, type=:mzml) # :nodoc:
    indices = []
    @scan_nums = []
    case type
    when :mzxml
      xml_string.each_line("\n") do |line|
        if line =~ /id="(\d+)".*>(\d+)</
          @scan_nums << $1.to_i
          indices << $2.to_i
        end
      end
      #doc = Nokogiri::XML.parse(xml_string, *Ms::Msrun::Nokogiri::PARSER_ARGS)
      #root_el = doc.root
      #raise RuntimeError, "expecting scan index!" unless root_el['name'] == 'scan'
      #root_el.children.each do |el|
      #  indices << el.text.to_i
      #  @scan_nums << el['id'].to_i
      #end
    when :mzml
      xml_string.each_line("\n") do |line|
        if line =~ /<offset idRef=".*scan=(\d+)".*>(\d+)</
          @scan_nums << $1.to_i
          indices << $2.to_i
        end
      end
    end
    indices << last_offset

    new_indices = []
    0.upto(indices.size-2) do |i|
      val = indices[i]
      next unless val
      new_indices[@scan_nums[i]] = [indices[i], indices[i+1] - indices[i]]
    end
    new_indices
  end

  private
  
  # non-destructive rewind: saves the position and returns it after the block
  # is executed. Returns the block's reply.
  def safe_io_rewind(io, &block)
    start = io.pos
    io.rewind
    reply = block.call 
    io.pos = start
    reply
  end
end
