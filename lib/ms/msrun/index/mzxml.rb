require 'ms/msrun/index'
require 'io/bookmark'

module Ms ; end
module Ms::Msrun ; end

module Ms::Msrun::Index
  class Mzxml < Array
    include Ms::Msrun::Index

    INDEX_TAG = 'indexOffset'
    INDEX_TAG_RE = %r{<#{INDEX_TAG}>(\d+)</#{INDEX_TAG}>}
      INDEX_REF_RE = %r{id="(\d+)".*>(\d+)</}

    # returns :scan
    def name ; :scan end

    def initialize(filename_or_io=nil)
      if filename_or_io
        openany(filename_or_io) do |io|
          set_from_file_io(io)
        end
      end
    end

    def self.index_list(filename_or_io)
      [ self.new(filename_or_io) ]
    end

    def header_startbyte_and_length
      [0,self[0][0]]
    end

    def scan_nums
      ids.map(&:to_i)
    end

    # returns boolean based on whether the file has a usable scan index
    # returns io to wherever it was when handed in.  TOPPView saves mzXML with
    # no index and so sets the indexOffset to 0.  In the case of a 0
    # indexOffset, the return is false.
    def self.has_index?(file_or_io)
      openany(file_or_io) do |inner_io|
        return_val = false
        cnt = 0
        if (path=inner_io.path) && (filesize=File.size(path))
          # we read the tail end of the file, looking for the pieces we need
          rewind_size = 300
          start_pos = filesize-rewind_size
          loop do
            inner_io.seek(start_pos)
            last_file_chunk = inner_io.read
            if last_file_chunk =~ %r{</msRun>}
              if last_file_chunk =~ INDEX_TAG_RE
                return_val = (Integer($1) > 0)
              end
              break
            end
            cnt += 1
            break if start_pos == 0
            start_pos = start_pos - rewind_size*(cnt**2)
            start_pos = 0 if start_pos < 0
          end
        else # scan through linearly if io doesn't respond to path
          while line=inner_io.gets
            if line =~ INDEX_TAG_RE
              return_val = (Integer($1) > 0)
            end
          end
        end
        return_val
      end # end openany
    end


    # takes a scan number as string or integer and retrieves the start byte
    # and length doublet
    # returns self
    def scan(scan_number)
      get_by_id(scan_number.to_s)
    end

    def set_from_indexless_io_by_regex(io)
      @ids = []
      start_positions_plus_final = []
      io.bookmark(true) do |inner_io|
        inner_io.each("\n") do |line|
          if md=%r{<scan .*num="(\d+)"}.match(line)
            start_positions_plus_final << ( inner_io.pos - line.bytesize + md.pre_match.bytesize )
            @ids << md[1]
          end
          if md=%r{</msRun>}.match(line)
            start_positions_plus_final << ( inner_io.pos - line.bytesize + md.pre_match.bytesize )
          end
        end
      end
      _index = start_positions_plus_final.each_cons(2).map {|a,b| [a, b-a] }
      self.replace(_index)
      self
    end

    # assumes io object is connected to a file so that "File.size(io.path)" is
    # valid.  sets the 'ids' attribute to be an array of id strings and replaces
    # self with a parallel array of doublets, where each doublet consists of a
    # start byte and length. returns self.
    def set_from_file_io(io)
      if Ms::Msrun::Index::Mzxml.has_index?(io)
        (index_start_byte_offset, length) = Ms::Msrun::Index.index_offset(io, index_offset_tag)
        xml_st = io.seek(index_start_byte_offset) && io.read(length)
        (@ids, start_bytes) = Ms::Msrun::Index.id_and_start_byte_arrays(xml_st, index_ref_re)
        doublets = start_bytes.push(index_start_byte_offset).each_cons(2).map {|s,sp1| [s, sp1 - s] }
        self.replace(doublets)
      else
        set_from_indexless_io_by_regex(io)
      end
      self
    end

  end
end

