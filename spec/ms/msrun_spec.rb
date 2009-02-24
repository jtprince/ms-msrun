require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'ms/msrun'

class MsrunSpec < MiniTest::Spec
  before do
    @file = '/home/jtprince/ms-msrun/test_files/twenty_scans.mzXML'
  end
  it 'reads' do

    Ms::Msrun.foreach(@file) do |scan|
      p scan.ms_level
      p scan.start_mz
      p scan.spectrum
      p scan.spectrum.mzs_and_intensities
    end
  end
end
