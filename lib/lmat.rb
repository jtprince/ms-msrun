
require 'gsl'
require 'narray'
#include Runarray

include Math
include GSL

## Labeled matrix

class Lmat

  NUM_BYTE_SIZE = 4

  # an narray object numerically labelling the m-axis
  attr_accessor :mvec
  # an narray object numerically labelling the n-axis
  attr_accessor :nvec
  # an mvec.size X nvec.size narray
  attr_accessor :mat

  ## Takes an array of narray objects
  def initialize(mat=nil, mvec=nil, nvec=nil)
    @mat = mat
    @mvec = mvec
    @nvec = nvec
  end

  class << self
    def [](*args)
      mat = NArray[*args]
      (nlen, mlen) = mat.shape
      obj = new(mat)
      obj.mvec = NArray[0...mlen]
      obj.nvec = NArray[0...nlen]
      obj
    end
  end

  def [](*args)
    @mat[*args]
  end

  def []=(*args)
    @mat.send('[]=', *args)
  end

  def slice=(*args)
    @mat.send(:slice, *args)
  end

  def slice(*args)
    @mat.slice(*args)
  end

  def inspect
    # TODO: needs work (see ruport pivotted table output)
    ["nvec=#{@nvec.inspect}", "mvec=#{@mvec.inspect}", "mat=#{@mat.inspect}"].join("\n")

    start = '   ' << nvec.to_a.join(", ") << "\n"
    start << ("    " + ("-" * (start.size - 4))) << "\n"
    mvec[].indgen!.each do |i|
      start << "#{mvec[i]} | " << @mat[true, i].to_a.join(" ") << "\n"
    end
    start
  end

  def max
    @mat.max
  end

  def dup
    a = Lmat.new
    a.mvec = self.mvec[]
    a.nvec = self.nvec[]
    a.mat = self.mat[]
    a
  end

  # returns self
  def from_lmat(file)
    File.open(file) do |io|
      (@mvec, @nvec) = [true, true].map do |iv|
        _len = io.read(4).unpack('I').first
        NArray.to_na( io.read(_len*NUM_BYTE_SIZE), 'sfloat' )
      end
      @mat = NArray.to_na(io.read, 'sfloat', @nvec.size, @mvec.size)
    end
    self
  end

  # returns self
  def from_lmata(file)
    # this can probably be made faster
    File.open(file) do |io|
      num_m = io.readline.to_i
      mline = io.readline.chomp
      @mvec = NArray.to_na( mline.split(' ').map {|v| v.to_f } )
      raise RuntimeError, "bad m vec size" if mvec.size != num_m
      num_n = io.readline.to_i
      nline = io.readline.chomp
      @nvec = NArray.to_na( nline.split(' ').map {|v| v.to_f } )
      raise RuntimeError, "bad n vec size" if nvec.size != num_n
      @mat = NArray.float(num_n, num_m)
      num_m.times do |m|
        line = io.readline.chomp!
        @mat[true, m] = line.split(' ').map {|v| v.to_f }
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
      num_scans = msrun.scan_count
      printf "Reading #{num_scans} spectra [.=100]" if $VERBOSE
      spectrum_cnt = 0
      msrun.each(:ms_level => 1) do |scan|
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
    arr.push(@mvec.size) if with_vec_lengths
    arr.push(@mvec.to_a.join(" "))
    arr.push(@nvec.size) if with_vec_lengths
    arr.push(@nvec.to_a.join(" "))
    (0...@mvec.size).each do |m_index|
      arr.push(@mat[true, m_index].to_a.join(" "))
    end
    arr.join("\n")
  end

  def ==(other)
     other != nil && self.class == other.class && @nvec == other.nvec && @mvec == other.mvec && @mat == other.mat
  end

  # returns a fresh lmat object
  def warp_cols(new_m_values, deep_copy=false)
    new_guy = self.dup
    new_guy.warp_cols!(new_m_values, deep_copy)
    new_guy
  end

  # warps the data in self based on interpolation of the cols.  Evaluates the
  # new_m_values for each column and returns a new lmat object with the m
  # values set to new_m_values.  nvec will be the same is in self.
  def warp_cols!(new_m_values, deep_copy=false)
    nvec[].indgen.each do |n|
      self[n,true] = Spline.alloc(Interp::AKIMA, mvec, self[n, true]).eval(new_m_values)
    end
    self.nvec = deep_copy ? self.nvec[] : self.nvec
    self.mvec = deep_copy ? new_m_values[] : new_m_values
    self
  end

  def write(file=nil, int_format_string='i')
    handle = $>
    if file; handle = File.open(file, "wb") end
    bin_string = ""
    bin_string << [@mvec.size].pack(int_format_string)
    bin_string << @mvec.to_s
    bin_string << [@nvec.size].pack(int_format_string)
    bin_string << @nvec.to_s
    bin_string << @mat.to_s
    handle.print bin_string
    if file; handle.close end
  end

  def print(file=nil)
    handle = $>
    handle = File.new(file, "w") if file
    handle.print( self.to_s(true) )
    handle.close if file
  end
end

class Lmat
  module Gnuplot

    # png output only right now, given no outfile, plot to X11
    def plot(outfile=nil)
      # modified from Hornet's eye
      require 'gnuplot'
      ::Gnuplot.open do |gp| 
        ::Gnuplot::SPlot.new(gp) do |plot|
          if outfile
            plot.terminal 'png'
            plot.output outfile
          end
          plot.pm3d
          plot.hidden3d
          plot.palette 'defined ( 0 "black", 51 "blue", 102 "green", ' +
            '153 "yellow", 204 "red", 255 "white" )'
          plot.xlabel 'n'
          plot.ylabel 'm'
          plot.data << ::Gnuplot::DataSet.new( self ) do |ds|
            ds.with = 'pm3d'
            ds.matrix = true
          end
        end
      end
    end

    def to_gsplot
      require 'gnuplot'
      [@mvec.to_a, @nvec.to_a, @mat.to_a].to_gsplot
    end
  end
  include Gnuplot
end

