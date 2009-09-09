require 'rexml/document'
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
    indices = []
    case type
    when :mzxml
      doc = REXML::Document.new xml_string
      root_el = doc.root
      raise RuntimeError, "expecting scan index!" unless root_el.attributes['name'] == 'scan'
      root_el.elements.each do |el|
        indices << el.text.to_i
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

  # takes an mzxml filename or io object
  # and returns an array of offsets and lengths for the scans
  # note that the offset 
  def self.index(filename_or_io)
    (ft, version) = Ms::Msrun.filetype_and_version(filename_or_io)
    tag = case ft
          when :mzml : MZML_INDEX_TAG
          when :mzxml : MZXML_INDEX_TAG
          end
    #######################33
    #
    #
    #
    #
    # WORKING HERE......  
    #
    #
    #
    size = 
      if filename_or_io.is_a? String
        File.size(filename_or_io)  # a filename
      else # a File object
      end
    File.open(filename_or_io) do |io|
      (offset, length) = index_offset(io, size, tag)
      io.pos = offset
      xml = io.read(length)
      self.index_to_array(xml, offset, ft)
    end
  end

end
