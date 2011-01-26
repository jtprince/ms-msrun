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

end
