require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'ms/msrun'


describe 'mzxml to search formats' do

  it 'creates mgf formatted files' do
    @file = TESTFILES + '/opd1/000.v1.mzXML'
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
        ms.to_mgf( k => v).is ""
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
      some_scans.each do |k,v|
        reply = ms.to_mgf(k => v)
        reply.should.match(/BEGIN.IONS/)
        reply.should.match(/END.IONS/)
      end
    end
    # TODO: should write some more specs here
  end

end
