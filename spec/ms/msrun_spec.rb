require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'ms/msrun'

module MsrunSpec

  before_all = lambda do |file|
    key = YAML.load_file(file + '.key.yml')
    nums = (1..key['scan_count'][0]).to_a  # define scan numbers
    [key, nums]
  end

  shared 'an msrun object' do

    it 'reads header information' do
      Ms::Msrun.open(@file) do |ms|
        @key['header'].each do |k,v|
          #puts "K: #{k} Vexp: #{v} Vact: #{ms.send(k.to_sym)}"
          ms.send(k.to_sym).is v
        end
      end
    end
    
    it 'can access random scans' do
      Ms::Msrun.open(@file) do |ms|
        scan = ms.scan(20)
        hash_match(@key['scans'][20], scan)
      end
    end

    it 'can read all scans' do
      num_required_scans = @key['scans'].size
      Ms::Msrun.open(@file) do |ms|
        ms.each do |scan|
          if hash = @key['scans'][scan.num]
            hash_match(hash, scan)
            num_required_scans -= 1
          end
        end
      end
      num_required_scans.is 0
    end

    it 'can read scans of a certain ms_level' do
      nums = [1,5,9,13,17]
      nums = [1,7,13,19] if @file.include? "j24"
      temp = nums.dup
      
      Ms::Msrun.open(@file) do |ms|
        ms.each(:ms_level => 1) do |scan|
          break if scan.num > 20 && !@file.include?("j24")
          scan.num.is temp.shift 
        end
      end
      
      nums = (1..24).to_a - nums
      Ms::Msrun.foreach(@file, :ms_level => 2) do |scan|
        break if scan.num > 20 && !@file.include?("j24")
        scan.num.is nums.shift 
      end
    end

    it 'can avoid reading spectra' do 
      nums = @nums.dup
      Ms::Msrun.foreach(@file, :spectrum => false) do |scan|
        scan.spectrum.nil?.ok
        scan.num.is nums.shift
      end
    end

    it 'can avoid reading precursor information' do 
      Ms::Msrun.foreach(@file, :precursor => false) do |scan|
        scan.precursor.nil?.ok
      end
    end

    it 'gives scan counts for different ms levels' do
      Ms::Msrun.open(@file) do |ms|
        @key['scan_count'].each do |index, count|
          ms.scan_count(index).is count
        end
      end
    end

    it 'gives start and end mz even if the information is not given' do
      Ms::Msrun.open(@file) do |ms|
        ms.start_and_end_mz_brute_force.is(@key['start_and_end_mz'][1])
      end
    end
  end

  describe 'reading an mzXML v1 file' do
    @file = TESTFILES + '/opd1/000.v1.mzXML'
    
    (@key, @nums) = before_all.call(@file)


    it 'can give start and end mz' do
      # scan has attributes startMz endMz
      Ms::Msrun.open(@file) do |ms|
        #ms.start_and_end_mz.is([300.0, 1500.0])
        ms.start_and_end_mz.is @key['start_and_end_mz'][1]
      end
    end

    behaves_like 'an msrun object'

  end

  describe 'reading an mzXML v2.0 file' do
    @file = TESTFILES + '/opd1/020.v2.0.readw.mzXML'
    (@key, @nums) = before_all.call(@file)
    behaves_like 'an msrun object'
  end

  describe 'reading an mzXML v2.1 file' do
    @file = TESTFILES + '/opd1/000.v2.1.mzXML'
    (@key, @nums) = before_all.call(@file)
    behaves_like 'an msrun object'

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
  
  describe 'reading an mzXML v3.1 file' do
    @file = TESTFILES + '/J/j24.mzXML'
    (@key, @nums) = before_all.call(@file)
    
    behaves_like 'an msrun object'
  end
  
  describe 'reading an mzML file' do
    @file = TESTFILES + '/J/j24.mzML'
    (@key, @nums) = before_all.call(@file)
    
    behaves_like 'an msrun object'
  end
  
  describe 'reading a compressed mzML file' do
    @file = TESTFILES + '/J/j24z.mzML'
    (@key, @nums) = before_all.call(@file)
    
    behaves_like 'an msrun object'
  end
end
