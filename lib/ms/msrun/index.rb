require 'axml'
require 'ms/msrun'

module Ms ; end
class Ms::Msrun ; end

module Ms::Msrun::Index
  MZXML_INDEX_TAG = 'indexOffset'
  MZML_INDEX_TAG = 'indexListOffset'

  # returns [index_offset, length_of_index]
  def self.index_offset(io, size, tag=MZML_INDEX_TAG, bytes_backwards=150) # :nodoc:
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
  def self.index_to_array(xml_string, last_offset, type=:mzml) # :nodoc:
    case type
    when :mzxml
      node = AXML.parse(xml_string)
      indices = []
      node.each do |child|
        indices[child['id'].to_i] = child.text.to_i
      end
    when :mzml
      raise NotImplementedError
    end
    indices << last_offset

    new_indices = []
    0.upto(indices.size-2) do |i|
      val = indices[i]
      next unless val
      new_indices[i] = [indices[i], indices[i+1] - indices[i]]
    end
    new_indices
  end

  # takes an mzxml filename
  # and returns an array of offsets and lengths for the scans
  # note that the offset 
  def self.index(filename)
    (ft, version) = Ms::Msrun.filetype_and_version(filename)
    tag = case ft
          when :mzml : MZML_INDEX_TAG
          when :mzxml : MZXML_INDEX_TAG
          end
    size = File.size(filename)
    File.open(filename) do |io|
      (offset, length) = index_offset(io, size, tag)
      io.pos = offset
      xml = io.read(length)
      self.index_to_array(xml, offset, ft)
    end
  end

end
