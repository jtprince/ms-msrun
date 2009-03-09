require 'base64'
require 'bsearch'

require 'ms/spectrum/compare'
require 'ms/spectrum/filter'

module Ms ; end

class Ms::Spectrum

  # m/z's
  attr_accessor :mzs  
  # intensities
  attr_accessor :intensities

  alias_method :ints, :intensities

  #######################
  ## CLASS METHODS:
  #######################

  def self.lazy(*args)
    Ms::Spectrum::LazyIO.new(*args)
  end

  def self.from_peaks(ar_of_doublets)
    _mzs = []
    _ints = []
    ar_of_doublets.each do |mz, int|
      _mzs << mz
      _ints << int
    end
    self.new(_mzs, _ints)
  end
  
  def initialize(mz_ar=[], intensity_ar=[])
    @mzs = mz_ar
    @intensities = intensity_ar
  end

  def mzs_and_intensities
    [@mzs, @intensities]
  end

  def ==(other)
    mzs == other.mzs && ints == other.ints
  end

  def [](array_index)
    [mzs[array_index], intensities[array_index]]
  end

  # yields(mz, inten) across the spectrum, or array of doublets if no block
  def peaks(&block)
    (m, i) = mzs_and_intensities
    m.zip(i, &block)
  end

  alias_method :each, :peaks
  alias_method :each_peak, :peaks

  # uses index function and returns the intensity at that value
  def intensity_at_mz(mz)
    if x = index(mz)
      intensities[x]
    else
      nil
    end
  end

  # less_precise should be a float
  # precise should be a float
  def equal_after_rounding?(precise, less_precise)
    # determine the precision of less_precise
    exp10 = precision_as_neg_int(less_precise)
    #puts "EXP10: #{exp10}"
    answ = ((precise*exp10).round == (less_precise*exp10).round)
    #puts "TESTING FOR EQUAL: #{precise} #{less_precise}"
    #puts answ
    (precise*exp10).round == (less_precise*exp10).round
  end


  # returns the index of the first value matching that m/z.  the argument m/z
  # may be less precise than the actual m/z (rounding to the same precision
  # given) but must be at least integer precision (after rounding)
  # implemented as binary search (bsearch from the web)
  def index(mz)
    mz_ar = mzs
    return_val = nil
    ind = mz_ar.bsearch_lower_boundary{|x| x <=> mz }
    if mz_ar[ind] == mz
      return_val = ind
    else 
      # do a rounding game to see which one is it, or nil
      # find all the values rounding to the same integer in the locale
      # test each one fully in turn
      mz = mz.to_f
      mz_size = mz_ar.size
      if ((ind < mz_size) and equal_after_rounding?(mz_ar[ind], mz))
        return_val = ind
      else # run the loop
        up = ind
        loop do
          up += 1
          if up >= mz_size
            break
          end
          mz_up = mz_ar[up]
          if (mz_up.ceil  - mz.ceil >= 2)
            break
          else
            if equal_after_rounding?(mz_up, mz)
              return_val = up
              return return_val
            end
          end
        end
        dn= ind
        loop do
          dn -= 1
          if dn < 0
            break
          end
          mz_dn = mz_ar[dn]
          if (mz.floor - mz_dn.floor >= 2)
            break
          else
            if equal_after_rounding?(mz_dn, mz)
              return_val = dn
              return return_val
            end
          end
        end
      end
    end
    return_val
  end

  # returns 1 for ones place, 10 for tenths, 100 for hundredths
  # to a precision exceeding 1e-6
  def precision_as_neg_int(float) # :nodoc:
    neg_exp10 = 1
    loop do
      over = float * neg_exp10
      rounded = over.round
      if (over - rounded).abs <= 1e-6
        break
      end
      neg_exp10 *= 10
    end
    neg_exp10
  end


end

module Ms::Spectrum::LazyIO

  # Saves the spectrum after reading it from disk (default=false).  [Set to
  # true if you want to do a few operations on a spectrum and don't want to
  # re-read from disk each time.  Use Spectrum#flush! when you think you are
  # done with it.]
  attr_accessor :save

  # sets save to true and returns the spectrum object for chaining commands
  def save!
    save = true
    self
  end

  def self.new(*args)
    if args.size == 5  # mzXMl
      Ms::Spectrum::LazyIO::Peaks.new(*args)
    elsif args.size == 9   # other
      Ms::Spectrum::LazyIO::Pair.new(*args)
    else
      raise RunTimeError, "must give 5 or 7 args for peak data and pair data respectively"
    end
  end

end

# stores an io object and the start and end indices and only evaluates the
# spectrum when information is requested
class Ms::Spectrum::LazyIO::Pair < Ms::Spectrum
  include Ms::Spectrum::LazyIO

  undef mzs=
  undef intensities=

  def initialize(io, mz_start_index, mz_num_bytes, mz_precision, mz_network_order, intensity_start_index, intensity_num_bytes, intensity_precision, intensity_network_order)
    @save = false
    @mzs = nil
    @intensities = nil
    @io = io

    @mz_start_index = mz_start_index
    @mz_num_bytes = mz_num_bytes
    @mz_precision = mz_precision
    @mz_network_order = mz_network_order

    @intensity_start_index = intensity_start_index
    @intensity_num_bytes = intensity_num_bytes
    @intensity_precision = intensity_precision
    @intensity_network_order = intensity_network_order

  end

  # beware that this converts the information on disk every time it is called.  
  def mzs
    return @mzs if @mzs
    @io.pos = @mz_start_index
    b64_string = @io.read(@mz_num_bytes)
    mzs_ar = Ms::Spectrum.base64_to_array(b64_string, @mz_precision, @mz_network_order)
    if save
      @mzs = mzs_ar
    else
      mzs_ar
    end
  end

  def flush!
    @mzs = nil
    @intensities = nil
  end

  # beware that this converts the information in @intensity_string every time
  # it is called.
  def intensities
    return @intensities if @intensities
    @io.pos = @intensity_start_index
    b64_string = @io.read(@intensity_num_bytes)
    inten_ar = Ms::Spectrum.base64_to_array(b64_string, @intensity_precision, @intensity_network_order)
    if save
      @intensities = inten_ar
    else
      inten_ar
    end
  end

end

class Ms::Spectrum::LazyIO::Peaks < Ms::Spectrum
  include Ms::Spectrum::LazyIO

  undef mzs=
  undef intensities=

  def initialize(io, start_index, num_bytes, precision, network_order)
    @data = nil
    @io = io
    @start_index = start_index
    @num_bytes = num_bytes
    @precision = precision
    @network_order = network_order
  end

  # removes any stored data
  def flush!
    @data = nil
  end

  # returns an array of alternating values: [mz, intensity, mz, intensity]
  def flat_peaks
    @io.pos = @start_index
    Ms::Spectrum.base64_to_array(@io.read(@num_bytes), @precision, @network_order)
  end

  # returns two arrays: an array of m/z values and an array of intensity
  # values.  This is the preferred way to access mzXML file information under
  # lazy evaluation
  def mzs_and_intensities
    return @data if @data
    @io.pos = @start_index
    b64_string = @io.read(@num_bytes)
    data = Ms::Spectrum.mzs_and_intensities_from_base64_peaks(b64_string, @precision, @network_order)
    if save
      @data = data
    else
      data
    end
  end

  # when using 'io' lazy evaluation on files with m/z and intensity data
  # interwoven (i.e., mzXML) it is more efficient to call 'mzs_and_intensities'
  # if you are using both mz and intensity data. 
  def mzs
    return @data.first if @data
    data = mzs_and_intensities
    if save
      @data = data
      @data.first
    else
      data.first
    end
    # TODO: this can be made slightly faster
  end

  # when using 'io' lazy evaluation on files with m/z and intensity data
  # interwoven (i.e., mzXML) it is more efficient to call
  # 'mzs_and_intensities'
  # if you are using both mz and intensity data. 
  def intensities(save=false)
    return @data.last if @data
    data = mzs_and_intensities
    if save
      @data = data
      @data.last
    else
      data.last
    end
    # TODO: this can be made slightly faster
  end

end


module Ms::Spectrum::Utils

  Unpack_network_float = 'g*'
  Unpack_network_double = 'G*'
  Unpack_little_endian_float = 'e*'
  Unpack_little_endian_double = 'E*'

  # an already decoded string (ready to be unpacked as floating point numbers)
  def string_to_array(string, precision=32, network_order=true)
    unpack_code = 
      if network_order
        if precision == 32
          Unpack_network_float
        elsif precision == 64
          Unpack_network_double
        end
      else ## little endian
        if precision == 32
          Unpack_little_endian_float
        elsif precision == 64
          Unpack_little_endian_double
        end
      end
    string.unpack(unpack_code)
  end

  # takes a base64 string and returns an array
  def base64_to_array(b64_string, precision=32, network_order=true)
    self.string_to_array(Base64.decode64(b64_string), precision, network_order)
  end

  def mzs_and_intensities_from_base64_peaks(b64_string, precision=32, network_order=true)
    data = base64_to_array(b64_string, precision, network_order)
    sz = data.size/2
    mz_ar = Array.new(sz)
    intensity_ar = Array.new(sz)
    ndata = []
    my_ind = 0
    data.each_with_index do |dat,ind|
      if (ind % 2) == 0  # even
        mz_ar[my_ind] = dat
      else
        intensity_ar[my_ind] = dat 
        my_ind += 1
      end
    end
    [mz_ar, intensity_ar]
  end
end

class Ms::Spectrum
  extend Utils
end


