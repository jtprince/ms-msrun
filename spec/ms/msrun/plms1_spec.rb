require 'spec_helper'

require 'ms/msrun/plms1'

describe 'plms1 - Prince Lab MS 1 specification' do

  before do
    @keyfile = TESTFILES + "/plms1_output.key" 
    times = [0.55, 0.9]
    scan_numbers = [1,2]
    spectra = [
      [[300.0, 301.5, 303.1], 
       [10, 20, 35.5]],
      [[300.5, 302, 303.6], 
       [11, 21, 36.5]]
    ]
    @plms1_obj = Ms::Msrun::Plms1.new(scan_numbers, times, spectra)
    @outfile = @keyfile.sub(/\.key$/, ".tmp")
  end

  it 'has a detailed specification' do
    spec = Ms::Msrun::Plms1::SPECIFICATION
    ok spec.is_a?(String)
    ok( spec.size > 50 )
  end

  it 'writes a plms1 file' do
    @plms1_obj.write(@outfile)
    ok File.exist?(@outfile)
    IO.read(@outfile, :mode => 'rb').is IO.read(@keyfile, :mode => 'rb')
    File.unlink(@outfile) if File.exist?(@outfile)
  end

  it 'reads a plms1 file' do
    obj = Ms::Msrun::Plms1.new.read(@keyfile)
    [:scan_numbers, :times, :spectra].each do |val|
      obj.send(val).enums @plms1_obj.send(val)
    end
  end

  it 'converts an Ms::Msrun object into a plms1 object' do
    plms1_obj = Ms::Msrun.open(TESTFILES + '/opd1/000.v2.1.mzXML') do |ms|
      ms.to_plms1
    end
    ok plms1_obj.is_a?(Ms::Msrun::Plms1)
    plms1_obj.scan_numbers.enums [1, 5, 9, 13, 17]
    plms1_obj.times.enums [0.44, 5.15, 10.69, 16.4, 22.37]
    # below is just frozen, not checked for accuracy but it does look
    # reasonable
    plms1_obj.spectra.first.first[0,4].enums [300.50518798828125, 301.43011474609375, 302.09600830078125, 302.87347412109375]
    plms1_obj.spectra.last.last[0,4].enums [7.0, 77503.0, 109867.0, 155067.0]
  end

end
