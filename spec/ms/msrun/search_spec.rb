require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'ms/msrun'

class SearchSpec < MiniTest::Spec

  xit 'works' do
    @file = '/home/jtprince/dev/ms-msrun/spec/files/opd1/000.v1.mzXML'
    params = {
      :bottom_mh => 300.0,
      :top_mh => 4500.0,
      :ms_levels => (2..-1),
      :min_peaks => 10,
    }

    # no scans:
    no_scans = [
      [:min_peaks, 1000],
      [:first_scan, 21],
      [:first_scan, 10000],
      [:last_scan, 0],
      [:ms_levels, (3..4)],
      [:ms_levels, 0], 
      [:ms_levels, 3], 
      [:top_mh, 0.0],
      [:bottom_mh, 5000],
    ]
    Ms::Msrun.open(@file) do |ms|
      no_scans.each do |k,v|
        ms.to_mgf(nil, k => v).must_equal ""
      end
    end

    some_scans = [
      [:min_peaks, 0],
      [:first_scan, 1],
      [:first_scan, 9],
      [:last_scan, 8],
      [:ms_levels, 2],
      [:ms_levels, (2..2)],
      [:ms_levels, (2...3)],
      [:top_mh, 1500],
      [:bottom_mh, 500],
    ]
    Ms::Msrun.open(@file) do |ms|
      no_scans.each do |k,v|
        reply = ms.to_mgf(nil, k => v)
        puts reply
        reply.must_match(/BEGIN.IONS/)
        reply.must_match(/END.IONS/)
      end
    end

  end

end
