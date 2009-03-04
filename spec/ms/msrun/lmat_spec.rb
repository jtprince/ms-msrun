require File.expand_path( File.dirname(__FILE__) + '/../../spec_helper' )

require 'ms/msrun/lmat'

class LmatUnitSpec < MiniTest::Spec

  def initialize(*args)
    @klass = Ms::Msrun::Lmat
    super(*args)
  end

  it 'can be created with no arguments' do
    obj1 = @klass.new
    obj1.class.must_equal @klass
  end

  xit 'can be created with arrays' do
    obj = @klass[[1,2,3],[4,5,6]]
    obj[0,0].must_equal 1
    obj[1,0].must_equal 4
    obj[1,2].must_equal 6
  end

  xit 'can find the max value' do
    obj = @klass[[1,2,3],[1,8,3]]
    obj.max.must_equal 8
  end

end
