require 'spec_helper'

require 'ms/msrun_spec'

describe 'an Ms::Msrun::Mzxml object' do
  behaves_like 'an Ms::Msrun'

  it 'can access random scans' do
    Ms::Msrun.open(@file) do |ms|
      scan = ms.scan(@random_scan_num)
      hash_match(@key['scans'][@random_scan_num], scan)
    end
  end

end

xdescribe 'reading an mzXML v1 file' do
  @file = TESTFILES + '/opd1/000.v1.mzXML'
  @random_scan_num = 20

  (@key, @nums) = before_all.call(@file)


  it 'can give start and end mz' do
    # scan has attributes startMz endMz
    Ms::Msrun.open(@file) do |ms|
      #ms.start_and_end_mz.is([300.0, 1500.0])
      ms.start_and_end_mz.is @key['start_and_end_mz'][1]
    end
  end

  behaves_like 'an Ms::Msrun'
end

xdescribe 'reading an mzXML v2.0 file' do
  @file = TESTFILES + '/opd1/020.v2.0.readw.mzXML'
  @random_scan_num = 20
  (@key, @nums) = before_all.call(@file)
  behaves_like 'an Ms::Msrun'
end

xdescribe 'reading an mzXML v2.1 file' do
  @file = TESTFILES + '/opd1/000.v2.1.mzXML'
  @random_scan_num = 20
  (@key, @nums) = before_all.call(@file)
  behaves_like 'an Ms::Msrun'

  it 'gives nil if scans do not have start and end mz info' do
    # scans do not have startMz endMz or filterLine
    Ms::Msrun.open(@file) do |ms|
      ms.start_and_end_mz.is([nil, nil])
    end
  end

  it 'gives start and end mz if filterLine present' do
    newname = @file + ".TMP.mzXML"
    File.open(newname, 'w') do |out|
      IO.foreach(@file) do |line|
        if line =~ /msLevel="1"/
          out.puts %Q{        filterLine="FTMS + p NSI Full ms [300.00-1500.00]"}
        end
        out.print line
      end
    end
    Ms::Msrun.open(newname) do |ms|
      ms.start_and_end_mz.is([300.0, 1500.0])
    end
    File.unlink(newname) if File.exist?(newname)
  end
end

xdescribe 'reading an mzXML v3.1 file' do
  @file = TESTFILES + '/J/j24.mzXML'
  @random_scan_num = 20
  (@key, @nums) = before_all.call(@file)

  behaves_like 'an Ms::Msrun'
end

xdescribe 'reading a compressed mzXML v3.1 file' do
  @file = TESTFILES + '/J/j24.mzXML'
  @random_scan_num = 20
  (@key, @nums) = before_all.call(@file)

  behaves_like 'an Ms::Msrun'
end

describe 'reading a short stubby mzXML file written by openms toppview' do
  @file = TESTFILES + '/openms/test_set.mzXML'
  @random_scan_num = 8849
  (@key, @nums) = before_all.call(@file)
  behaves_like 'an msrun object'
end


