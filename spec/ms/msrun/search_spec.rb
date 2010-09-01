require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'fileutils'
require 'ms/msrun'


describe 'mzXML or mzML to search formats' do

  @mzxml_file1 = TESTFILES + '/opd1/000.v1.mzXML'
  @mzxml_file2 = TESTFILES + '/J/j24z.mzXML'
  @mzml_file2 = TESTFILES + '/J/j24z.mzML'
  @key = { :ms2 => TESTFILES + '/J/key-j24z.ms2', 
    :mgf => TESTFILES + '/J/key-j24z.mgf',
    :subset_mgf => TESTFILES + '/J/key-j10z.mgf'
  }

  it 'creates mgf formatted files' do
    params = {
      :bottom_mh => 300.0,
      :top_mh => 4500.0,
      :ms_levels => (2..-1),
      :min_peaks => 10,
    }

    # no scans:
    no_scans = [
      [:min_peaks, 1000],
      [:included_scans, []],
      [:ms_levels, (3..4)],
      [:ms_levels, 0], 
      [:ms_levels, 3], 
      [:top_mh, 0.0],
      [:bottom_mh, 5000],
    ]
    Ms::Msrun.open(@mzxml_file1) do |ms|
      no_scans.each do |k,v|
        ms.to_mgf( k => v ).is ""
      end
    end

    some_scans = [
      [:min_peaks, 0],
      [:included_scans, (9..20).to_a],
      [:included_scans, (1..10).to_a],
      [:ms_levels, 2],
      [:ms_levels, (2..2)],
      [:ms_levels, (2...3)],
      [:top_mh, 1500],
      [:bottom_mh, 500],
    ]
    Ms::Msrun.open(@mzxml_file1) do |ms|
      some_scans.each do |k,v|
        reply = ms.to_mgf(k => v)
        reply.should.match(/BEGIN.IONS/)
        reply.should.match(/END.IONS/)
      end
    end
    # TODO: should write some more specs here
  end

  it 'creates ms2 formatted files' do
    outfile = @mzxml_file2.chomp(".mzXML") + ".ms2"
    Ms::Msrun.open(@mzxml_file2) do |ms|
      ms.to_ms2(:output => outfile)
    end
    ok FileUtils::cmp(outfile, @key[:ms2])
    File.unlink_f(outfile)
  end
  
  it 'allows for selecting specific scans in output' do
    outfile = @mzml_file2.chomp(".mzML") + ".mgf"
    
    Ms::Msrun.open(@mzml_file2) do |ms|
      ms.to_mgf(:output => outfile, :included_scans => [1,2,3,8,10,11,15,17,18,20,24])
    end
    
    ok FileUtils::cmp(outfile, @key[:subset_mgf])
  end

  it 'converts files to search formats with a simple convenience method' do
    [:mgf, :ms2].each do |format|
      outfile = @mzxml_file2.chomp(".mzXML") + ".3." + format.to_s

      # :run_id allows the user to tack on meaningful additions to the
      # filename
      Ms::Msrun::Search.convert(format, @mzxml_file2, :run_id => 3)

      ok FileUtils.cmp(outfile, @key[format])
      File.unlink_f(outfile)
    end
  end
end
