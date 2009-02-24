require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'ms/msrun'

class MsrunSpec < MiniTest::Spec
  before do
    @file = '/home/john/ms-msrun/test_files/twenty_scans.mzXML'
  end
  it 'reads' do

    Ms::Msrun.foreach(@file) do |scan|
      p scan.tic
      p scan.ms_level
      p scan.start_mz
      p scan.spectrum
      (mz, inten) = scan.spectrum.mzs_and_intensities
      puts "COUTNS: "
      p scan.num_peaks
      p mz.size
    end
  end
end
