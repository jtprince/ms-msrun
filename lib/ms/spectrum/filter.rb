require 'ms/spectrum'

module Ms
  class Spectrum
    module Filter

      def filter(by=:bins, opts={})
        send("filter_by_#{by}".to_sym, opts)
      end

      # filters by binning the mz field
      # bin_width is in m/z units
      # num_peaks is the top peaks to include per bin
      def filter_by_bins(opts={})
        (bw, np) = {:bin_width => 100, :num_peaks => 7 }.merge(opts).values_at(:bin_width, :num_peaks)

        stop = bw
        track = []
        track_all = [track]
        ints = self.intensities
        self.each do |mz,int|
          if mz > stop
            stop += bw
            track = []
            track_all << track
          end
          track << [int, mz]
        end

        include = []
        track_all.each do |track|
          track.sort!
          start = (track.size < np) ? track.size : np
          include.push( *( track[-start,np]) )
        end

        ret_ints = []
        ret_mzs = include.map {|int, mz| [mz, int] }.sort.map {|mz,int| ret_ints << int ; mz }

        return Spectrum.new([ret_mzs, ret_ints])
      end

    end
    include Filter
  end
end
