require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

require 'ms/spectrum/filter'


# when you switch order the return intensities are swapped:
class Array
  def rev_ab
    each {|v| (v[0], v[1]) = v[1], v[0] }
  end
end

class FilterSpec

  describe 'filtering spectra' do
    before do
      @a = Ms::Spectrum.new([[0,5,10, 15,16,17,18, 20.1], [0,1,2, 3,8,10,4, 0]])
      @null = Ms::Spectrum.new([[],[]])
    end

    it 'filters spectra' do
      spec = @a.filter(:bins, :bin_width => 10, :num_peaks => 2)
      spec.mzs.enums [5,10,16,17,20.1]
      spec.intensities.enums [1,2,8,10,0]

      @a.filter(:bins, :bin_width => 100, :num_peaks => 8).is @a
      @a.filter(:bins, :bin_width => 1, :num_peaks => 1).is @a
      @a.filter(:bins, :bin_width => 1, :num_peaks => 0).is @null
    end

  end
end


