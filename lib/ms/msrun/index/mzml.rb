require 'nokogiri'
require 'ms/msrun/nokogiri'
require 'io/bookmark'

module Ms ; end
module Ms::Msrun ; end

module Ms::Msrun::Index
  class Mzml < Array
    include Ms::Msrun::Index

    INDEX_TAG = 'indexListOffset'
    INDEX_REF_RE = %r{<offset\s+idRef="([^"]+)".*>(\d+)</}



    Scan_re = %r{scan=(\d+)}

    attr_accessor :name
    attr_accessor :header_startbyte_and_length

    def initialize(pairs=[], ids=[], name)
      super(pairs)
      @ids, @name = ids, name
    end


    # given a nokogiri index fragment string (note, this should not have
    # namespaces associated with it since the root of the doc is not parsed!)
    # and the index offset value (the byte where the index list actually
    # begins)
    #
    # returns an array of index objects.
    def self.create_indices_from_index_fragment(string, index_offset)
      doc = ::Nokogiri::XML.parse(string, *Ms::Msrun::Nokogiri::PARSER_ARGS)
      root = doc.root
      raise "bad parse" unless root.name == 'indexList'
      root.children.map do |index_n|
        _ids = []
        offsets = index_n.children.map do |offset_node|
          _ids << offset_node['idRef']
          offset_node.text.to_i
        end
        offset_pairs = offsets.push(index_offset).each_cons(2).map {|s,sp1| [s, sp1 - s] }
        Ms::Msrun::Index::Mzml.new(offset_pairs, _ids, index_n['name'].to_sym)
      end
    end

    # returns an array of all indices.
    # Typically this will be a spectrum index and a chromatogram index, but
    # it may also just be a spectrum index.
    def self.index_list(io_or_filename)
      (spectrum_index, chromatogram_index) = openany(io_or_filename) do |io|
        if has_index?(io)
          # this needs a revamping, right??? broken.... right????
          (index_offset, length_of_index) = Ms::Msrun::Index.index_offset(io, Ms::Msrun::Index::Mzml::INDEX_TAG)
          create_indices_from_index_fragment(io.seek(index_offset) && io.read(length_of_index), index_offset)
        else
          spectrum_index = Ms::Msrun::Index::Mzml.new_from_indexless(io, :spectrum)
          (last_spec_start, last_spec_length) = spectrum_index.last
          # we can do this because chromatograms are guaranteed to come after
          # spectrumList (per mzML 1.1.0)
          io.seek(last_spec_start + last_spec_length)
          chromatogram_index = Ms::Msrun::Index::Mzml.new_from_indexless(io, :chromatogram)
          [spectrum_index, chromatogram_index]
        end
      end
      header_sb_and_l = find_header_startbyte_and_length(io_or_filename)
      indices = [spectrum_index, chromatogram_index].compact
      indices.each {|index| index.header_startbyte_and_length = header_sb_and_l }
      indices
    end

    def self.find_header_startbyte_and_length(file_or_io)
      start = nil
      _length = nil
      end_pos = nil
      openany(file_or_io) do |io|
        io.rewind
        io.each_line("\n") do |line|
          if md = line.match(/<mzML /)
            start = io.pos - (line.bytesize - md.pre_match.bytesize)
            break
          end
        end
        io.each_line("\n") do |line|
          if md = line.match(/<run /)
            end_pos = io.pos - (line.bytesize - md.pre_match.bytesize)
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
    # where it is at.  returns nil if no objects found.  
    def self.new_from_indexless(thing, name)
      # I would implement this with an XML parser, but Nokogiri does not
      # easily expose the context object (looked into it fairly heavily).  So,
      # this ends up being more straightforward (and probably faster anyway).
      openany(thing) do |io|
        start_re, index_it_re, close_re = 
          case name.to_sym
          when :spectrum
            [%r{<spectrumList [^>]*count="(\d)+"}, %r{<spectrum .*?id="([^"]+)".*?>}, %r{</spectrum>}]
          when :chromatogram
            [%r{<chromatogramList [^>]*count="(\d)+"}, %r{<chromatogram .*?id="([^"]+)".*?>}, %r{</chromatogram>}]
          end
        _ids = []
        start_indices_plus_tail = []
        # find the list tag and see how many things there are
        cnt = nil
        while line = io.gets  
          if md = start_re.match(line)
            cnt = md[1].to_i
            break
          end
        end
        if cnt
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
          Ms::Msrun::Index::Mzml.new(doublets, _ids, name)
        end
      end
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
        lines.any? {|line| line =~ /<indexedmzML / }
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
