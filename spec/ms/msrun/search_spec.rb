require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'ms/msrun'

class SearchSpec < MiniTest::Spec

  it 'works' do
    @file = '/home/jtprince/ms-msrun/spec/files/opd1/000.v1.mzXML'
    Ms::Msrun.open(@file) do |ms|
      ms.to_mgf(nil, :min_peaks => 10)
      flunk
    end
  end

end
