
module Ms ; end
class Ms::Msrun ; end

module Ms::Msrun::Index

  # a list of index objects
  class List < Array

    # takes an mz[X]ML filename or io object
    # and returns an array of offsets and lengths for the scans
    def initialize(filename_or_io)
      ft = Ms::Msrun.filetype(filename_or_io)
      openany(filename_or_io) do |io|
        case ft
        when :mzxml
          self[0] = Ms::Msrun::Index::Mzxml.new(io)
        when :mzml
          set_from_file_io(io)
        end
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

    def self.has_index?(io)
      Ms::Msrun::Index.const_get(Ms::Msrun.filetype(io).to_s.capitalize).has_index?(io)
    end


  end

end
