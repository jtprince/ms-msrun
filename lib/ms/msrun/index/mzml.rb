module Ms ; end
class Ms::Msrun ; end

module Ms::Msrun::Index
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

    attr_accessor :header_startbyte_and_length

    # returns an array (Ms::Msrun::Index::List object) of all the indices
    def self.index_list(io)
      if has_index?(io)
        # this needs a revamping, right??? broken.... right????
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
        io.bookmark(true) do |inner_io|
          spectrum_index = Ms::Msrun::Index::Mzml.new_from_indexless_io_by_regex(inner_io, :spectrum, Ms::Msrun::Index::Mzxml::SpectrumList_re, Ms::Msrun::Index::Mzxml::Spectrum_re, Ms::Msrun::Index::Mzxml::Spectrum_close_re)
          (last_spec_start, last_spec_length) = spectrum_index.last
          inner_io.seek(last_spec_start + last_spec_length)
          chromatogram_index = Ms::Msrun::Index::Mzml.new_from_indexless_io_by_regex(inner_io, :chromatogram, Ms::Msrun::Index::Mzxml::ChromatogramList_re, Ms::Msrun::Index::Mzxml::Chromatogram_re, Ms::Msrun::Index::Mzxml::Chromatogram_close_re)
        end
      end
      header_sb_and_l = find_header_startbyte_and_length(io)
      [spectrum_index, chromatogram_index].each {|index| index.header_startbyte_and_length = header_sb_and_l }
      [spectrum_index, chromatogram_index]
    end

    def self.find_header_startbyte_and_length(io)
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

    # returns boolean based on whether the file has been indexed.
    # returns io to wherever it was when handed in.
    def self.has_index?(file_or_io)
      openany(file_or_io) do |inner_io|
        lines = []
        while (line=inner_io.gets)
          lines << line
          break if line =~ /<mzML /
        end
        lines.any? {|line| line =~ /<indexedMzML / }
      end
    end

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
