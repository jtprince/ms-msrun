require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )

require 'lmat'

describe 'an lmat' do

  def initialize(*args)
    end

  @klass = Lmat
  @lmatfile = TESTFILES + "/lmat/tmp1.lmat"
  @lmatafile = TESTFILES + "/lmat/tmp1.lmata"
  @lmat = Lmat.new
  super(*args)

  it 'can be created with no arguments' do
    obj1 = @klass.new
    obj1.class.should.equal @klass
  end

  it 'can be created with arrays' do
    obj = @klass[[1,2,3],[4,5,6]]
    obj[0,0].should.equal 1
    obj[1,0].should.equal 4
    obj[1,2].should.equal 6
    obj.mvec.should.equal [0,1]
    obj.nvec.should.equal [0,1,2]
  end

  it 'can find the max value' do
    obj = @klass[[1,2,3],[1,8,3]]
    obj.max.should.equal 8
  end

  it 'can be read from lmat file' do
    x = Lmat.new
    x.from_lmat(@lmatfile)
    x.nvec.size.should.equal 30
    x.mvec.size.should.equal 40
    x.mat.size.should.equal 1200
    x.mat.shape.should.equal [30,40]
  end

  xit 'can write an lmat file' do
    output = @lmatfile + ".TMP"
    @lmat.from_lmat(@lmatfile) 
    @lmat.write(output)
    IO.read(output).should.equal IO.read(@lmatfile)
    File.unlink(output) if File.exist?(output)
  end

end
