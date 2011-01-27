
require 'ms/msrun'
require 'stringio'

module Ms
  class Msrun

    # if given scans, will use those, or optionally takes a block where an
    # array of ms1 scans are yielded and it expects Enumerable scans back.
    def to_plms1(scans=nil)
      times = []
      scan_numbers = []
      spectra = []

      unless scans
        scans = []
        self.each(:ms_level => 1, :precursor => false) do |scan|
          scans << scan
        end
      end

      if block_given?
        scans = yield(scans)
      end

      scans.each do |scan|
        times << scan.time
        scan_numbers << scan.num
        spec = scan.spectrum
        spectra << [spec.mzs.to_a, spec.intensities.to_a]
      end
      plms1 = Plms1.new
      plms1.times = times
      plms1.scan_numbers = scan_numbers
      plms1.spectra = spectra
      plms1
    end

    # Prince Lab MS 1: a simple format for reading and writing 
    # MS1 level mass spec data
    # 
    # see Ms::Msrun::Plms1::SPECIFICATION for the file specification
    class Plms1
      SPECIFICATION =<<-HERE
        # The file format contains no newlines but is shown here broken into lines for
        # clarity.  Data should be little endian.  Comments begin with '#' but are not
        # part of the spec. Angled brackets '<>' indicate the data type and square
        # brackets '[]' the name of the data. An ellipsis '...' represents a
        # continuous array of data points.

        <uint32>[Number of scans]
        <uint32>[scan number] ...  # array of scan numbers as uint32
        <float64>[time point] ...  # array of time points as double precision floats (in seconds)
        # this is a repeating unit based on [Number of scans]:
        <uint32>[Number of data rows]  #  almost always == 2 (m/z, intensity)
        # this is a repeating unit based on [Number of data rows]
        <uint32>[Number of data points]
        <float64>[data point] ...  # array of data points as double precision floats
      HERE

      # an array of scan numbers
      attr_accessor :scan_numbers
      # an array of time data
      attr_accessor :times
      # an array that contains parallel rows of arrays holding the actual data
      # these are NOT bona fide spectra objects
      attr_accessor :spectra

      def initialize(_scan_numbers=[], _times=[], _spectra=[])
        (@scan_numbers, @times, @spectra) = [_scan_numbers, _times, _spectra]
      end

      # returns an array of Integers
      def read_uint32(io, cnt=1)
        io.read(cnt*4).unpack("V*")
      end

      # returns an array of Floats
      def read_float64(io, cnt=1)
        io.read(cnt*8).unpack("E*")
      end

      # returns self for chaining
      def read(io_or_filename)
        io = 
          if io_or_filename.is_a?(String)
            filename = io_or_filename
            File.open(io_or_filename,'rb')
          else ; io_or_filename end

        num_scans = read_uint32(io)[0]
        @scan_numbers = read_uint32(io, num_scans)
        @times = read_float64(io, num_scans)
        @spectra = num_scans.times.map do
         read_uint32(io)[0].times.map do
            read_float64(io, read_uint32(io)[0])
          end
        end
        io.close if filename
        self
      end

      def write_uint32(out, data)
        to_pack = data.is_a?(Array) ? data : [data]
        out << to_pack.pack('V*')
      end

      def write_float64(out, data)
        to_pack = data.is_a?(Array) ? data : [data]
        out << to_pack.pack('E*')
      end

      # returns the string if no filename given 
      def write(filename=nil)
        out = 
          if filename
            File.open(filename,'w')
          else
            StringIO.new
          end
        write_uint32(out, spectra.size)
        write_uint32(out, scan_numbers)
        write_float64(out, times)
        spectra.each do |spectrum|
          write_uint32(out, spectrum.size)  # number of rows
          spectrum.each do |row|
            write_uint32(out, row.size)
            write_float64(out, row)
          end
        end
        if filename
          out.close
          filename
        else
          out.string
        end
      end
    end
  end
end
