require 'ms/mass'

module Ms
  class Msrun

    #config :first_scan, 0, :short => 'F', &c.integer # first scan
    #config :last_scan, 1e12, :short => 'L', &c.integer  # last scan
    ## if not determined to be +1, then create these charge states
    #config( :charge_states, [2,3], :short => 'c') {|v| v.split(',') }
    #config :bottom_mh, 0, :short => 'B', &c.float # bottom MH+ 
    #config :top_mh, -1.0, :short => 'T', &c.float # top MH+
    #config :min_peaks, 0, :short => 'P', &c.integer # minimum peak count
    #config :ms_levels, 2..-1, :short => 'M', &c.range  # ms levels to export

    module Search

      # returns a string unless :output given (may be a String (filename) or a
      # writeable IO object in which case the data is written to file or io
      # and the number of spectra written is returned
      def to_mgf(opts={})
        opts = {
          :output => nil,  # an output file or io object
          :bottom_mh => 0.0,
          :top_mh => nil,
          :ms_levels => (2..-1),  # range or intger, -1 at end will be substituted for last level
          :min_peaks => 0,
          :first_scan => 0,
          :last_scan => nil,
          :prec_mz_precision => 6,
          :prec_int_precision => 2,
          :frag_mz_precision => 5,
          :frag_int_precision => 1,
          :charge_states_for_unknowns => [2,3],
          :determine_plus_ones => false,
        }.merge(opts)
       (_first_scan, _last_scan, _bottom_mh, _top_mh, _ms_levels, _min_peaks, _charge_states_for_unknowns, _prec_mz_precision, _prec_int_precision, _frag_mz_precision, _frag_int_precision, _determine_plus_ones) = opts.values_at(:first_scan, :last_scan, :bottom_mh, :top_mh, :ms_levels, :min_peaks, :charge_states_for_unknowns, :prec_mz_precision, :prec_int_precision, :frag_mz_precision, :frag_int_precision, :determine_plus_ones)

       sep = ' '

       if _top_mh.nil? || _top_mh == -1
         _top_mh = nil
       end

       if _last_scan.nil? or _last_scan == -1
         _last_scan = self.scan_nums.last
       end

       if !_ms_levels.is_a?(Integer) && _ms_levels.last == -1
         _ms_levels = ((_ms_levels.first)..(scan_counts.size-1))
       end

        prec_string = "PEPMASS=%0.#{_prec_mz_precision}f %0.#{_prec_int_precision}f\n"
        frag_string = "%0.#{_frag_mz_precision}f%s%0.#{_frag_int_precision}f\n"

        any_output(opts[:output]) do |out, out_type|
          each_scan(:ms_level => _ms_levels) do |scan|
            sn = scan.num

            next unless sn >= _first_scan and sn <= _last_scan
            next unless scan.num_peaks >= _min_peaks

            
            if _determine_plus_ones
              # tic under precursor > 95% and true = save the spectrum info
              if scan.plus1?(0.95)
                _charge_states = [1]
              end
            end

            chrg_sts = scan.precursor.charge_states
            if chrg_sts.nil? || !chrg_sts.first.is_a?(Integer)
              chrg_sts = _charge_states_for_unknowns
            end

            pmz = scan.precursor && scan.precursor.mz

            chrg_sts.each do |z|
              mh = (pmz * z) - (z - 1)*Ms::Mass::PROTON
              next unless (mh >= _bottom_mh) 
              next unless (mh <= _top_mh) if _top_mh
              out.puts "BEGIN IONS"
              out.puts "TITLE=#{self.parent_basename_noext}.#{sn}.#{sn}.#{z}"
              out.puts "CHARGE=#{z}+"
              out.printf(prec_string, pmz, scan.precursor.intensity)
              scan.spectrum.peaks do |mz,int|
                out.printf(frag_string, mz, sep, int )
              end
              out.puts "END IONS\n\n"
            end
          end

          if out_type == :string_io
            out.string
          else
            count
          end
        end

      end


      # yields an IO object and the type input (:io, :filename, :string_io)
      def any_output(arg, &block)
        # this is pretty ugly, can we clean up?
          if arg.is_a? IO  # an IO object passed in
            block.call(arg, :io)
          elsif arg && arg.is_a?(String)  # open the file
            File.open(arg, 'w') do |io|
              block.call(io, :filename)
            end
          else  # nil
            st_io = StringIO.new
            block.call(st_io, :string_io)
          end
      end


    end

    include Search
  end
end
