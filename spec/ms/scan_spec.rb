require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'ms/msrun'

class ScanUnitSpec < MiniTest::Spec

  before do
    @scan = Ms::Scan.new
    @scan.precursor = Ms::Precursor.new
    @scan.spectrum = Ms::Spectrum.new([[1,2,3,4], [2,4,4,2]])
  end


 it 'determines if its +1 or not' do
    # these have not been checked for accuracy, just sanity
    reply = [0.1,2.5, 3.5, 5].map do |prec_mz|
      @scan.precursor.mz = prec_mz
      @scan.plus1?(-0.1)
    end
    reply.all? {|v| v == true }.must_equal true

    reply = [0.1,2.5, 3.5, 5].map do |prec_mz|
      @scan.precursor.mz = prec_mz
      @scan.plus1?(1.0)
    end
    reply.all? {|v| v == false }.must_equal true

    reply = [0.1,2.5, 3.5, 5].map do |prec_mz|
      @scan.precursor.mz = prec_mz
      @scan.plus1?(0.5)
    end
    reply.must_equal [false, false, true, true]
  end
end
