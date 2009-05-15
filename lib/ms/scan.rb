require 'ms/precursor'

module Ms ; end

#              0      1          2      3         4        5           6     7
#        8 
MsScanAtts =  [:num, :ms_level, :time, :start_mz, :end_mz, :num_peaks, :tic, :precursor, :spectrum]

Ms::Scan = Struct.new(*MsScanAtts)

# time in seconds
# everything else in float/int

class Ms::Scan
 
  def to_s
    "<Scan num=#{num} ms_level=#{ms_level} time=#{time}>"
  end

  undef_method :inspect
  def inspect
    atts = %w(num ms_level time start_mz end_mz) 
    display = atts.map do |att|
      if val = send(att.to_sym)
        "#{att}=#{val}"
      else
        nil
      end
    end
    display.compact!
    spec_display = 
      if spectrum
        spectrum.mzs.size
      else
        'nil'
      end
    "<Ms::Scan:#{__id__} " + display.join(", ") + " precursor=#{precursor.inspect}" + " spectrum(size)=#{spec_display}" + " >"
  end

  # if > cutoff is below the precusure, then it is considered a +1 charge,
  # otherwise > 1
  # Algorithm from the MzXML2Search code by Jimmy Eng
  def plus1?(cutoff=0.95)
    prec_mz = precursor.mz 
    mzs, intens = spectrum.mzs_and_intensities
    tic = 0.0
    below = 0.0
    mzs.zip(intens) do |mz, int|
      if mz < prec_mz
        below += int
      end
      tic += int
    end
    tic == 0.0 || below/tic > cutoff
  end


  # returns the string (space delimited): "ms_level num time [prec_mz prec_inten]"
  def to_index_file_string
    arr = [ms_level, num, time]
    if precursor then arr << precursor.mz end
    if x = precursor.intensity then arr << x end
    arr.join(" ")
  end

end


