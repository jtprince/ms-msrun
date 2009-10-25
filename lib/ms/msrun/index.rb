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

  # takes an mzxml filename or io object
  # and returns an array of offsets and lengths for the scans
  # note that the offset 
  def initialize(filename_or_io)
    (ft, version) = Ms::Msrun.filetype_and_version(filename_or_io)
    tag = case ft
          when :mzml : MZML_INDEX_TAG
          when :mzxml : MZXML_INDEX_TAG
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
    (offset, length) = index_offset(io, size, tag)
    io.pos = offset
    xml = io.read(length)
    io.close if filename_or_io.is_a?(String)
    self.replace( index_to_array(xml, offset, ft) )
    self
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
      xml_string.each("\n") do |line|
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
      raise NotImplementedError
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
end
