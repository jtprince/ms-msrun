require 'spec_helper')

require 'ms/msrun'

Scan1 = '<scan num="4"
        msLevel="2"
        peaksCount="74"
        polarity="+"
        scanType="Full"
        retentionTime="PT3.64S"
        collisionEnergy="35"
        lowMz="325"
        highMz="2000"
	basePeakMz="1090.05"
	basePeakIntensity="789939"
	totIonCurrent="2.27206e+006">
    <precursorMz precursorIntensity="1.52022e+006">1222.033203</precursorMz>
    <peaks precision="32"
           byteOrder="network"
           pairOrder="m/z-int">Q7Rw2EUK8ABDuWjORQSgAEO5+NhFHLAAQ8gNTEU10ABD2QKcRLCAAEPcdCJFxBAAQ92bFkZzPABEAIucRSbQAEQJuBJFTyAARAqM7EX9+ABECsPMRT7QAEQPyWRF1LgARBoLhETLoABEHjlsRZQwAEQefjRE3yAARCERUkYvuABEIYiKRMMAAEQh01xFifAARCNEKEYpuABEI3kcRWrgAEQjvPhFHRAARCZm7EZtNABEJpXwRnyMAEQmy+pF4QAARCb/RkWfIABEKY28RZQIAEQ6gGBFyHAARDrIYEVEsABEPLuARXJgAEQ9RdREQ8AARD2BIEaV7ABEP7tcRdzoAERChMxHVPcAREK2gEZQAABEQwDkRa/gAEREyLxE3UAARFDwhEXwKABEUT7uRTPQAERTbZZFhfAARFQQvEaK9gBEVOfcRaDQAERWgBJGY5AARFh4ukcWmgBEWMAqRppEAERZgzhF+SgARFsBakXOKABEW4IiR8GBAERbw5pGUvwARFwJcEUooABEXat2RmUoAERegQRHibgARF7FmkU2AABEY6z2RgBIAERvwkxF/pgARHJ9YEYXEABEcrySRgFkAER0gDJINYsARHTFKEeJloBEdPgURoz8AER3hVhIlXggRHfIAEd2YgBEd/acRuh2AER4IiI/gAAARIW+tEVbkABEhdH8RnqcAESIQXhJQNswRIhimEecEgBEiH0cRvKMAESInkBGguYARIp9kEWm0ABEkUz6RdCQAESR//BFH5AARJQhYkYGbABEmxG2RjnYAA==</peaks>
  </scan>
  </scan>
'

Scan2 = '<scan num="4"
        msLevel="2"
        peaksCount="74"
        polarity="+"
        scanType="Full"
        retentionTime="PT3.64S"
        collisionEnergy="35"
        lowMz="325"
        highMz="2000"
	basePeakMz="1090.05"
	basePeakIntensity="789939"
	totIonCurrent="2.27206e+006">
    <precursorMz precursorIntensity="1.52022e+006">1222.033203</precursorMz>
    <peaks precision="32"
           byteOrder="network"
           pairOrder="m/z-int">Q7Rw2EUK8ABDuWjORQSgAEO5+NhFHLAAQ8gNTEU10ABD2QKcRLCAAEPcdCJFxBAAQ92bFkZzPABEAIucRSbQAEQJuBJFTyAARAqM7EX9+ABECsPMRT7QAEQPyWRF1LgARBoLhETLoABEHjlsRZQwAEQefjRE3yAARCERUkYvuABEIYiKRMMAAEQh01xFifAARCNEKEYpuABEI3kcRWrgAEQjvPhFHRAARCZm7EZtNABEJpXwRnyMAEQmy+pF4QAARCb/RkWfIABEKY28RZQIAEQ6gGBFyHAARDrIYEVEsABEPLuARXJgAEQ9RdREQ8AARD2BIEaV7ABEP7tcRdzoAERChMxHVPcAREK2gEZQAABEQwDkRa/gAEREyLxE3UAARFDwhEXwKABEUT7uRTPQAERTbZZFhfAARFQQvEaK9gBEVOfcRaDQAERWgBJGY5AARFh4ukcWmgBEWMAqRppEAERZgzhF+SgARFsBakXOKABEW4IiR8GBAERbw5pGUvwARFwJcEUooABEXat2RmUoAERegQRHibgARF7FmkU2AABEY6z2RgBIAERvwkxF/pgARHJ9YEYXEABEcrySRgFkAER0gDJINYsARHTFKEeJloBEdPgURoz8AER3hVhIlXggRHfIAEd2YgBEd/acRuh2AER4IiI/gAAARIW+tEVbkABEhdH8RnqcAESIQXhJQNswRIhimEecEgBEiH0cRvKMAESInkBGguYARIp9kEWm0ABEkUz6RdCQAESR//BFH5AARJQhYkYGbABEmxG2RjnYAA==</peaks>
'

Scan3 = '<scan num="4"
        msLevel="2"
        peaksCount="74"
        polarity="+"
        scanType="Full"
        retentionTime="PT3.64S"
        collisionEnergy="35"
        lowMz="325"
        highMz="2000"
	basePeakMz="1090.05"
	basePeakIntensity="789939"
	totIonCurrent="2.27206e+006">
    <precursorMz precursorIntensity="1.52022e+006">1222.033203</precursorMz>
    <peaks precision="32"
           byteOrder="network"
           pairOrder="m/z-int">Q7Rw2EUK8ABDuWjORQSgAEO5+NhFHLAAQ8gNTEU10ABD2QKcRLCAAEPcdCJFxBAAQ92bFkZzPABEAIucRSbQAEQJuBJFTyAARAqM7EX9+ABECsPMRT7QAEQPyWRF1LgARBoLhETLoABEHjlsRZQwAEQefjRE3yAARCERUkYvuABEIYiKRMMAAEQh01xFifAARCNEKEYpuABEI3kcRWrgAEQjvPhFHRAARCZm7EZtNABEJpXwRnyMAEQmy+pF4QAARCb/RkWfIABEKY28RZQIAEQ6gGBFyHAARDrIYEVEsABEPLuARXJgAEQ9RdREQ8AARD2BIEaV7ABEP7tcRdzoAERChMxHVPcAREK2gEZQAABEQwDkRa/gAEREyLxE3UAARFDwhEXwKABEUT7uRTPQAERTbZZFhfAARFQQvEaK9gBEVOfcRaDQAERWgBJGY5AARFh4ukcWmgBEWMAqRppEAERZgzhF+SgARFsBakXOKABEW4IiR8GBAERbw5pGUvwARFwJcEUooABEXat2RmUoAERegQRHibgARF7FmkU2AABEY6z2RgBIAERvwkxF/pgARHJ9YEYXEABEcrySRgFkAER0gDJINYsARHTFKEeJloBEdPgURoz8AER3hVhIlXggRHfIAEd2YgBEd/acRuh2AER4IiI/gAAARIW+tEVbkABEhdH8RnqcAESIQXhJQNswRIhimEecEgBEiH0cRvKMAESInkBGguYARIp9kEWm0ABEkUz6RdCQAESR//BFH5AARJQhYkYGbABEmxG2RjnYAA==</peaks>
           </scan>
           </scan>
           </msRun>
'

#class Sha1Spec < MiniTest::Spec
  #def initialize(*args)
    #@files = %w(000.v1.mzXML 020.v2.0.readw.mzXML 000.v2.1.mzXML).map do |file|
      #TESTFILES + "/opd1/#{file}"
    #end
    #super(*args)
  #end

  ### NOTE: this does NOT match up to real files yet!
  #it 'can read xml scans with extra or missing tags' do
    #Scan.new(from_xml)    
  #end


#end
