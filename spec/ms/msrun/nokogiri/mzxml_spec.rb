require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

require 'ms/msrun/nokogiri/mzxml'

class NokogiriMzxmlSpec < MiniTest::Spec

SCAN_XML =<<XML 
      <scan num="3"
        msLevel="2"
        peaksCount="51"
        polarity="+"
        scanType="full"
        centroided="1"
        retentionTime="PT2.750000S"
	startMz="110.0000"
	endMz="905.0000"
        lowMz="159.8986"
        highMz="482.0345"
	basePeakMz="358.6158"
	basePeakIntensity="2560436.0000"
	totIonCurrent="8015729.0000">
    <precursorMz precursorIntensity="1531503.000000"
                 collisionEnergy="35.000000">446.009033</precursorMz>
    <peaks precision="32">Qx/mDEZpdABDJsd4Rh28AENeltBGK/AAQ2CwEkYWfABDYsPERbfQAENwijJFEIAAQ3Gq/EWMAABDk0dgRpQ6AEOY3ihHydYAQ5ku7kCAAABDpqoURvb4AEOnERA/gAAAQ6nsxEaIxABDq29kR5NkgEOuRrBF34gAQ7BnuEXe+ABDsN2kRlcgAEOywyxIglLAQ7NO1EocRtBDs8tcSPW9gEO0WnxImHGAQ7TIpEcOlgBDuqvSRa6YAEO8fR5FAaAAQ76HaEWAcABDwupIRwccAEPIWjRHIh4AQ8ljqkbWfgBDybYKQEAAAEPKWBxHLHMAQ8vM6EcOswBDzDDkRXHAAEPRCQhG02QAQ9JspkaRYgBD0yJyRYpIAEPVeFhF/jAAQ9Yo7EirwGBD1nmcSb04OEPW8a5JZGwwQ9dnekkp9JBD199wRoyyAEPcftJFNNAAQ92pcEZSqABD3tMgRhZoAEPfNDxHPmYAQ9+dqkY0RABD4kouRvsQAEPmKWRFfQAAQ+cC8kbCsgBD7l3URrcaAEPxBGxGsIYA</peaks>
  </scan>
XML

  before do
  end

  def initialize(*args)
    super *args
  end

  it 'can give start of peaks data and length' do
    (start, length) =  Ms::Msrun::Nokogiri::Mzxml.new(nil,nil,nil).peakdata_start_and_length(SCAN_XML)
    SCAN_XML[start, length][0,2].must_equal 'Qx'
    SCAN_XML[start, length][-5..-1].must_equal 'GsIYA'
  end

end
