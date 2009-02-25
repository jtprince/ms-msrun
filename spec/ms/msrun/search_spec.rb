require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'ms/msrun'

class SearchSpec < MiniTest::Spec

  it 'works' do
    @file = '/home/jtprince/ms-msrun/spec/files/opd1/000.v1.mzXML'
    params = {
      :bottom_mh => 300.0,
      :top_mh => 4500.0,
      :ms_levels => (2..-1),
      :min_peaks => 10,
    }

    # no scans:
    no_scans = {
      :min_peaks => 1000,
      :first_scan => 21,
      :first_scan => 10000,
      :last_scan => 0,
      :ms_levels => (3..4),
      :ms_levels => 0, 
      :ms_levels => 3, 
      :top_mh => 0.0,
      :bottom_mh => 8000,
    }
    Ms::Msrun.open(@file) do |ms|
      no_scans.each do |k,v|
        puts "here"
        ms.to_mgf(nil, k => v).must_equal ""
      end
    end
  end

end
