require 'ms/msrun'
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
    
      # Returns a string unless :output given (may be a String (filename) or a
      # writeable IO object in which case the data is written to file or io
      # and the number of spectra written is returned
      def to_mgf(opts={})
        to_search(:mgf, opts)
      end
      
      #Same as to_mgf, but for the ms2 format
      def to_ms2(opts={})
        to_search(:ms2, opts)
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
      
      
      private
      
      #Performs the common actions for the different formats, and calls the command for the given format
      def to_search(format, opts)
        opts = set_opts(opts)
        
        sep = ' '
        frag_string = "%0.#{opts[:frag_mz_precision]}f%s%0.#{opts[:frag_int_precision]}f\n"
        prec_string = "PEPMASS=%0.#{opts[:prec_mz_precision]}f %0.#{opts[:prec_int_precision]}f\n"
        
        any_output(opts[:output]) do |out, out_type|
          each_scan(:ms_level => opts[:ms_levels]) do |scan|
            sn = scan.num
            
            next unless opts[:included_scans].include? sn
            next unless sn >= opts[:first_scan] and sn <= opts[:last_scan]
            next unless scan.num_peaks >= opts[:min_peaks]
            
            opts, chrg_sts, pmz = get_vals(opts, scan)
            
            chrg_sts.each do |z|
              mh = (pmz * z) - (z - 1)*Ms::Mass::PROTON
              next unless (mh >= opts[:bottom_mh]) 
              next unless (mh <= opts[:top_mh]) if opts[:top_mh]
              
              mgf_header(out, scan, sn, z, prec_string, pmz) if format == :mgf
              ms2_header(out, scan, sn, z, mh, pmz) if format == :ms2
              
              scan.spectrum.peaks do |mz,int|
                out.printf(frag_string, mz, sep, int)
              end
              
              out.puts "END IONS\n\n" if format == :mgf
            end
          end
          
          if out_type == :string_io
            out.string
          else
            count
          end
        end
      end
      
      #Creates the mgf-type spectrum header
      def mgf_header(out, scan, sn, z, prec_string, pmz)
        out.puts "BEGIN IONS"
        out.puts "TITLE=#{self.parent_basename_noext}.#{sn}.#{sn}.#{z}"
        out.puts "CHARGE=#{z}+"
        out.printf(prec_string, pmz, scan.precursor.intensity)
      end
      
      #Creates the ms2-type spectrum header
      def ms2_header(out, scan, sn, z, mh, pmz)
        out.puts "S\t#{sn}\t#{sn}\t#{pmz}"
        out.puts "I\tRTime\t#{scan.time}"
        out.puts "Z\t#{z}\t#{mh}"
      end
      
      #Sets options and other variables to be used by the to_* methods.
      def set_opts(opts)
        opts = {
          :output => nil,  # an output file or io object
          :bottom_mh => 0.0,
          :top_mh => nil,
          :ms_levels => (2..-1),  # range or intger, -1 at end will be substituted for last level
          :min_peaks => 0,
          :first_scan => 0,
          :last_scan => nil,
          :prec_mz_precision => 6,
          :prec_int_precision => 6,
          :frag_mz_precision => 5,
          :frag_int_precision => 1,
          :charge_states_for_unknowns => [2,3],
          :determine_plus_ones => false,
          :included_scans => (1..scan_count).to_a  #An array of scans to include in the output. :ms_levels precedes :included_scans.
        }.merge(opts)
        
        if opts[:top_mh].nil? || opts[:top_mh] == -1
          opts[:top_mh] = nil
        end
        
        if opts[:last_scan].nil? or opts[:last_scan] == -1
          opts[:last_scan] = self.scan_nums.last
        end
        
        if !opts[:ms_levels].is_a?(Integer) && opts[:ms_levels].last == -1
          opts[:ms_levels] = ((opts[:ms_levels].first)..(scan_counts.size-1))
        end
        
        opts
      end
      
      #Factored out method. Simply serves to reduce the size of to_search
      def get_vals(opts, scan)
        if opts[:determine_plus_ones]
          # tic under precursor > 95% and true = save the spectrum info
          if scan.plus1?(0.95)
            opts[:charge_states] = [1]
          end
        end
        
        chrg_sts = scan.precursor.charge_states
        if chrg_sts.nil? || !chrg_sts.first.is_a?(Integer)
          chrg_sts = opts[:charge_states_for_unknowns]
        end
        
        pmz = scan.precursor && scan.precursor.mz
        
        [opts, chrg_sts, pmz]
      end
    end

    include Search
  end
end
