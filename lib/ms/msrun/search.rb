require 'ms/mass'

module Ms
  class Msrun
  
    module Search

      # convenience method to convert a file to a search format
      # @param [Symbol] format valid format symbol
      # @param [String] file the filename (relative or absolute)
      # @param [Hash] opts other options taken by Search:to_search
      # @option opts [Object] :run_id concatenated to output filename with :run_id_cat
      # @option opts [String] :run_id_cat ('.') concatenate run_id
      # @example
      #   Ms::Msrun::Search.convert(:mgf, "myfilename.mzXML", :run_id => 25, :run_id_cat => '__')
      #   # writes to the file: "myfilename__25.mgf"
      def self.convert(format, file, opts={})
        opts[:run_id_cat] ||= '.'
        new_filename = file.chomp(File.extname(file))
        if opts[:run_id]
          new_filename << opts[:run_id_cat].to_s << opts[:run_id].to_s
        end
        new_filename << '.' << format.to_s
        Ms::Msrun.open(file) do |ms|
          ms.to_search(format, :output => new_filename)
        end
      end
    
      # returns a string unless :output given (may be a String (filename) or a
      # writeable IO object in which case the data is written to file or io
      # and the number of spectra written is returned
      def to_mgf(opts={})
        to_search(:mgf, opts)
      end
      
      # same as to_mgf, but for the ms2 format
      def to_ms2(opts={})
        to_search(:ms2, opts)
      end
      
      # performs the common actions for the different formats, and calls the command for the given format
      def to_search(format, opts)
        opts = set_opts(opts)
        
        sep = ' '
        frag_string = "%0.#{opts[:frag_mz_precision]}f%s%0.#{opts[:frag_int_precision]}f\n"
        mgf_prec_string = "PEPMASS=%0.#{opts[:prec_mz_precision]}f %0.#{opts[:prec_int_precision]}f\n"
        
        any_output(opts[:output]) do |out, out_type|
          each_scan(:ms_level => opts[:ms_levels]) do |scan|
            sn = scan.num
            
            next unless sn >= opts[:first_scan] and sn <= opts[:last_scan]
            next unless scan.num_peaks >= opts[:min_peaks]
            
            opts, chrg_sts, pmz = get_vals(opts, scan)
            
            chrg_sts.each do |z|
              mh = (pmz * z) - (z - 1)*Ms::Mass::PROTON
              next unless (mh >= opts[:bottom_mh]) 
              next unless (mh <= opts[:top_mh]) if opts[:top_mh]
              
              case format
              when :mgf ; mgf_header(out, scan, sn, z, mgf_prec_string, pmz)
              when :ms2 ; ms2_header(out, scan, sn, z, mh, pmz)
              end
              
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
        [['S', sn, sn, pmz], ['I', 'RTime', scan.time], ['Z', z, mh]].each do |ar|
          out.puts ar.join("\t")
        end
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

    protected

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


    include Search
  end
end



#config :first_scan, 0, :short => 'F', &c.integer # first scan
#config :last_scan, 1e12, :short => 'L', &c.integer  # last scan
## if not determined to be +1, then create these charge states
#config( :charge_states, [2,3], :short => 'c') {|v| v.split(',') }
#config :bottom_mh, 0, :short => 'B', &c.float # bottom MH+ 
#config :top_mh, -1.0, :short => 'T', &c.float # top MH+
#config :min_peaks, 0, :short => 'P', &c.integer # minimum peak count
#config :ms_levels, 2..-1, :short => 'M', &c.range  # ms levels to export


