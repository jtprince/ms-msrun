
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

  # converts msrun object to a labeled matrix
  # takes hash with symbols as keys
  def from_msrun(msrun, args)
    opt = {
      :inc_mz => 1.0,
      :behave_mz => 'sum', 
      :baseline=> 0.0,

      #:start_tm => 0.0, 
      #:end_tm => 3600.0,
      #:inc_tm => nil,
      
      #:start_mz => 400.0, 
      #:end_mz => 1500.0,
    }
    opt.merge!(args)

    (st, en) = msrun.start_and_end_mz
    unless st && en
      msg = ["scanning spectrum for start and end m/z values"]
      msg << "(use :start_mz and :end_mz options to avoid this)"
      warn msg
      (st, en) = msrun.start_and_end_mz_brute_force
    end
    opt[:start_mz] ||= st
    opt[:end_mz] ||= en

    #unless opt[:start_tm] then opt[:start_tm] = times.first end
    #unless opt[:end_tm] then opt[:end_tm] = times.last end

    if opt[:inc_tm]
      raise NotImplementedError, "haven't implemented interpolation in ruby yet! (#{File.basename(__FILE__)}: #{__LINE__})"
    else ## No interpolation
      times = []
      @nvec = nil
      vecs = []
      puts $VERBOSE
      num_scans = msrun.scan_count
      printf "Reading #{num_scans} spectra [.=100]" if $VERBOSE
      puts "HIYA3"
      spectrum_cnt = 0
      msrun.each do |scan|
        spectrum = scan.spectrum
        times << scan.time
        #(mz,inten) = spectrum_to_mz_and_inten(spectrum, VecD)
        # TODO: Figure out a shallow copy here:
        # perhaps we'll make spectra Vec objects by default in future and
        # then we'd be set...
        mzs = NArray.new(spectrum.mzs)
        intens = NArray.new(spectrum.intensities)
        (x,y) = mzs.inc_x(intens, opt[:start_mz], opt[:end_mz], opt[:inc_mz], opt[:baseline], opt[:behave_mz])
        spectrum_cnt += 1
        if spectrum_cnt % 100 == 0
          printf "." if $VERBOSE ; $stdout.flush
        end
        @nvec ||= x # just need the first one for the x values
        vecs << y
      end
      puts "DONE!" if $VERBOSE
      @mvec = NArray.new(times)
      @mat = vecs
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

