require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

require 'ms/spectrum/compare'

# when you switch order the return intensities are swapped:
class Array
  def rev_ab
    each {|v| (v[0], v[1]) = v[1], v[0] }
  end
end

class CompareSpec < MiniTest::Spec
  include Ms

  before do
    @a = Spectrum.new([[0,2,3,4], [5,6,7,8]])
    @b = Spectrum.new([[0, 1.5, 3.5, 5.5], [9,10,11,12]])

    @c = Spectrum.new([[0, 1], [8,9]])
    @d = Spectrum.new([[0.6, 0.75], [10,11]])
  end

  it 'compares spectra' do
    # array form:
    @c.compare(@d).rev_ab.must_equal( @d.compare(@c) )
    @c.compare(@d).must_equal [[8, 10, 0.6]]

    # block form
    exp = [[5,9], [6,10], [7,11]]
    # default radius 1.0
    @a.compare(@b) do |int_a, int_b| 
     exp.delete([int_a, int_b])
    end
    exp.size.must_equal 0
  end

  it 'computes similarity score' do
    @a.sim_score(@a, :radius => 0.1).must_equal 1.0
    # this is just frozen, not verified:
    @a.sim_score(@b).must_be_close_to 0.702945603476432, 0.000001
  end

  it 'computes a pic score' do
    @a.pic_score(@a, :radius => 0.01).must_equal 100.0
    @a.pic_score(@d, :radius => 0.01).must_equal 0.0
    # frozen:
    @a.pic_score(@b).must_be_close_to 68.4981684981685, 0.000001 
  end
end


