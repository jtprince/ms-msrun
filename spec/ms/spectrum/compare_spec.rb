require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

require 'ms/spectrum/compare'

# when you switch order the return intensities are swapped:
class Array
  def rev_ab
    each {|v| (v[0], v[1]) = v[1], v[0] }
  end
end

module CompareSpec

  describe 'comparison of spectra' do

    before do
      @a = Ms::Spectrum.new([[0,2,3,4], [5,6,7,8]])
      @b = Ms::Spectrum.new([[0, 1.5, 3.5, 5.5], [9,10,11,12]])

      @c = Ms::Spectrum.new([[0, 1], [8,9]])
      @d = Ms::Spectrum.new([[0.6, 0.75], [10,11]])
    end

    it 'compares spectra' do
      # array form:
      @c.compare(@d).rev_ab.is( @d.compare(@c) )
      @c.compare(@d).is [[8, 10, 0.6]]

      # block form
      exp = [[5,9], [6,10], [7,11]]
      # default radius 1.0
      @a.compare(@b) do |int_a, int_b| 
        exp.delete([int_a, int_b])
      end
      exp.size.is 0
    end

    it 'computes similarity score' do
      @a.sim_score(@a, :radius => 0.1).is 1.0
      # this is just frozen, not verified:
      @a.sim_score(@b).should.be.close 0.702945603476432, 0.000001
    end

    it 'computes a pic score' do
      @a.pic_score(@a, :radius => 0.01).is 100.0
      @a.pic_score(@d, :radius => 0.01).is 0.0
      # frozen:
      @a.pic_score(@b).should.be.close 68.4981684981685, 0.000001 
    end
  end
end


