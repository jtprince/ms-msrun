require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )

require 'lmat'

describe 'an lmat' do

  @klass = Lmat
  @lmatfile = TESTFILES + "/lmat/tmp1.lmat"
  @lmatafile = TESTFILES + "/lmat/tmp1.lmata"
  @lmatafile_small = TESTFILES + "/lmat/tmp2.lmata"

  before do
    @lmat = Lmat.new
  end

  it 'can be created with no arguments' do
    obj1 = @klass.new
    obj1.class.is @klass
  end

  it 'can be created with arrays' do
    obj = @klass[[1,2,3],[4,5,6]]
    obj[0,0].is 1
    obj[2,1].is 6
    obj[1,0].is 2
    obj.mvec.enums [0,1]
    obj.nvec.enums [0,1,2]
  end

  it 'can find the max value' do
    obj = @klass[[1,2,3],[1,8,3]]
    obj.max.is 8
  end

  it 'can be read from lmat file' do
    x = Lmat.new
    x.from_lmat(@lmatfile)
    x.nvec.size.is 30
    x.mvec.size.is 40
    x.mat.size.is 1200
    x.mat.shape.is [30,40]
  end

  it 'can write an lmat file' do
    begin
      output = @lmatfile + ".TMP"
      @lmat.from_lmat(@lmatfile) 
      @lmat.write(output)
      IO.read(output).is IO.read(@lmatfile)
    ensure
      File.unlink(output) if File.exist?(output)
    end
  end

  it 'can be read from an lmata file' do
    x = Lmat.new.from_lmata(@lmatafile)
    x.nvec.size.is 30
    x.mvec.size.is 40
    x.mat.size.is 1200
    x.mat.shape.is [30,40]
  end

  it 'can print an lmata file' do
    begin
      output = @lmatafile_small + ".TMP"
      @lmat.from_lmata(@lmatafile_small) 
      @lmat.print(output)
      ars = [output, @lmatafile_small].map do |file|
        IO.read(file).chomp.gsub("\n", " ").split(/\s+/).map {|v| v.to_f }
      end
      ars.first.enums ars.last
    ensure
      File.unlink(output) if File.exist?(output)
    end
  end

  it 'can warp data columns' do
    @lmat.from_lmata(@lmatafile_small)
    puts "Warp before"
    p @lmat
    deep_copy = true
    @lmat.plot("before.png")
    new_lmat = @lmat.warp_cols(NArray.float(7).indgen(12).collect {|v| v + 2.5 }, deep_copy)
    new_lmat.isa Lmat
    new_lmat.plot("after.png")
    puts "Warp after"
    p new_lmat
    ## TODO: NEEEED tests HERE
  end

  it 'can plot' do
    @lmat.from_lmata(@lmatafile_small)
    @lmat.plot("mypng.png")
    @lmat.isa Lmat
  end

end
