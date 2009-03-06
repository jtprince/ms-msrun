
require 'runarray'
include Runarray

## Labeled matrix

class Lmat
  attr_accessor :mvec
  attr_accessor :nvec
  # an array of narray objects
  attr_accessor :mat

  ## Takes an array of narray objects
  def initialize(mat=nil, mvec=nil, nvec=nil)
    @mat = mat
    @mvec = mvec
    @nvec = nvec
  end

  def max
    max = mat[0][0]
    mat.each do |row|
      row.each do |v|
        max = v if v > max
      end
    end
    max
  end

  # returns self
  def from_lmat(file)
    string = IO.read(file)
    mdim = string.unpack("i")
    @mvec = NArray.new(string.unpack("f#{mdim}"))
    ndim = string.unpack("i")
    @nvec = NArray.new(string.unpack("f#{ndim}"))
    rows = []
    mdim.times do
      rows << string.unpack("f#{ndim}")
    end
    @mat = rows
    self
  end

  # returns self
  def from_lmata(file)
    # this can probably be made faster
    File.open(file) do |io|
      num_m = io.readline.to_i
      mline = io.readline.chomp
      @mvec = NArray.new( mline.split(' ').map {|v| v.to_f } )
      raise RuntimeError, "bad m vec size" if mvec.size != num_m
      num_n = io.readline.to_i
      nline = io.readline.chomp
      @nvec = NArray.new( nline.split(' ').map {|v| v.to_f } )
      raise RuntimeError, "bad n vec size" if nvec.size != num_n
      @mat = NArray.new(num_m)
      num_m.times do |m|
        line = io.readline
        line.chomp!
        @mat[m] = NArray.new(line.split(' ').map {|v| v.to_f })
      end
    end
    self
  end

  # converts raw times and spectrum to a labeled matrix
  # times is an array (or VecI object)
  # where each row = [mz,inten,mz,inten...]
  # takes hash with symbols as keys
  # if inc_tm is undefined, then times from the times array will be used
  def from_times_and_spectra(times, spectra, args)
    opt = {
      :start_mz => 400.0, 
      :end_mz => 1500.0,
      :inc_mz => 1.0,
      :behave_mz => 'sum', 

      :start_tm => 0.0, 
      :end_tm => 3600.0,
      :inc_tm => nil,

      :baseline=> 0.0,
    }
    opt.merge!(args)
    unless opt[:start_tm] then opt[:start_tm] = times.first end
    unless opt[:end_tm] then opt[:end_tm] = times.last end
    
    if opt[:inc_tm]
      raise NotImplementedError, "haven't implemented interpolation in ruby yet! (#{File.basename(__FILE__)}: #{__LINE__})"
    else ## No interpolation
      if times.first != opt[:start_tm] || times.last != opt[:end_tm]
        abort "haven't implemented yet! (#{File.basename(__FILE__)}: #{__LINE__})"
      else
        @mvec = NArray.new(times)
        give_vecs = true
        vecs = spectra.map do |spectrum|
          #(mz,inten) = spectrum_to_mz_and_inten(spectrum, VecD)
          # TODO: Figure out a shallow copy here:
          # perhaps we'll make spectra Vec objects by default in future and
          # then we'd be set...
          mzs = NArray.new(spectrum.mzs)
          intens = NArray.new(spectrum.intensities)
          (x,y) = mzs.inc_x(intens, opt[:start_mz], opt[:end_mz], opt[:inc_mz], opt[:baseline], opt[:behave_mz])
          @nvec = x # ends up being the last one, but that's OK
          y
        end
        @mat = vecs
      end
    end
    self  
  end

  # outputs vec lengths if set to true
  def to_s(with_vec_lengths=false)
    arr = []
    if with_vec_lengths; arr.push(@mvec.size) end
    arr.push(@mvec.join(" "))
    if with_vec_lengths; arr.push(@nvec.size) end
    arr.push(@nvec.join(" "), @mat.map {|v| v.join(" " ) }.join("\n")).join("\n")
  end

  def ==(other)
     other != nil && self.class == other.class && @nvec == other.nvec && @mvec == other.mvec && @mat == other.mat
  end

  # converts a single array of alternating m/z intensity values to two
  # separate arrays
  # (maybe implement in Ruby::Inline?)
  # the answer is given in terms of arrs_as (object of class "arrs_as" must
  # respond to "[]" and create a certain sized array with arrs_as.new(size))
  def spectrum_to_mz_and_inten(spectrum, arrs_as=Array)
    half_size = spectrum.size / 2
    mzs = arrs_as.new(half_size)
    intens = arrs_as.new(half_size)
    mz = true 
    spectrum.each_index do |i|
      if mz
        mzs[i/2] = spectrum[i]
        mz = false
      else
        mz = true
        intens[(i-1)/2] = spectrum[i]
      end
    end
    [mzs, intens]
  end

  def write(file=nil)
    handle = $>
    if file; handle = File.open(file, "wb") end
    bin_string = ""
    bin_string << [@mvec.size].pack("i")
    bin_string << @mvec.pack("f*")
    bin_string << [@nvec.size].pack("i")
    bin_string << @nvec.pack("f*")
    bin_string << @mat.flatten.pack("f*")
    handle.print bin_string
    if file; handle.close end
  end

  def print(file=nil)
    handle = $>
    if file; handle = File.new(file, "w") end
    handle.print( self.to_s(true) )
    #$stdout.print( self.to_s(true) )
    if file; handle.close end
  end

end

