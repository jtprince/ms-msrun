require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'ms/msrun'

describe 'a scan' do

  before do
    @scan = Ms::Scan.new
    @scan.precursor = Ms::Precursor.new
    @scan.spectrum = Ms::Spectrum.new([[1,2,3,4], [2,4,4,2]])
  end

 it 'can determine if its +1 or not' do
    # these have not been checked for accuracy, just sanity
    reply = [0.1,2.5, 3.5, 5].map do |prec_mz|
      @scan.precursor.mz = prec_mz
      @scan.plus1?(-0.1)
    end
    reply.all? {|v| v == true }.ok

    reply = [0.1,2.5, 3.5, 5].map do |prec_mz|
      @scan.precursor.mz = prec_mz
      @scan.plus1?(1.0)
    end
    reply.all? {|v| v == false }.ok

    reply = [0.1,2.5, 3.5, 5].map do |prec_mz|
      @scan.precursor.mz = prec_mz
      @scan.plus1?(0.5)
    end
    reply.vals_are [false, false, true, true]
  end
end
