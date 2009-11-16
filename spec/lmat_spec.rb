require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )

require 'lmat'

describe 'an lmat' do

  @klass = Lmat
  @lmatfile = TESTFILES + "/lmat/tmp1.lmat"
  @lmatafile = TESTFILES + "/lmat/tmp1.lmata"
  @lmat = Lmat.new

  it 'can be created with no arguments' do
    obj1 = @klass.new
    obj1.class.is @klass
  end

  it 'can be created with arrays' do
    obj = @klass[[1,2,3],[4,5,6]]
    obj[0,0].is 1
    obj[2,1].is 6
    obj[1,0].is 2
    obj.mvec.vals_are [0,1]
    obj.nvec.vals_are [0,1,2]
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

  xit 'can write an lmat file' do
    output = @lmatfile + ".TMP"
    @lmat.from_lmat(@lmatfile) 
    @lmat.write(output)
    IO.read(output).is IO.read(@lmatfile)
    File.unlink(output) if File.exist?(output)
  end

end
