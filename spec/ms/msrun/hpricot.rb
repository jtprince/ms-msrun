require File.expand_path( File.dirname(__FILE__) + '/../../spec_helper' )

require 'ms/msrun/hpricot/mzxml'

class HpricotSpec < MiniTest::Spec

  before do
    @scan_xml = '<scan num="19"
        msLevel="2"
        peaksCount="9"
        polarity="+"
        scanType="Full"
        retentionTime="PT25.23S"
        collisionEnergy="35"
        lowMz="390"
        highMz="2000"
	basePeakMz="1621.51"
	basePeakIntensity="17748"
	totIonCurrent="54989">
    <precursorMz precursorIntensity="720317">1460.54834</precursorMz>
    <peaks precision="32"
           byteOrder="network"
           pairOrder="m/z-int">RE84xESwAABEYq6wRNLAAESW7sRGFigARJ/nyEVuYABEo+vkRMgAAESqV85FjhgARLQ3FEXvmABEuEH6RdfoAETKsCpGiqgA</peaks>
  </scan>'
    @scan_xml_short = @scan_xml.split("\n")[0...-1].join("\n")
    @scan_xml_long = @scan_xml + "\n</scan>"
    @basic_info = { :num => 19, :ms_level => 2, :time => 25.23 }
    @prec_info = {:intensity => 720317, :mz => 1460.54834 }
    @spectrum = nil # for now
  end


  it 'reads normal xml' do
    Ms::Msrun::Hpricot::Mzxml.parse_scan
  end


end
