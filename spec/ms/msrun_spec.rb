require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

require 'ms/msrun'

module MsrunSpec
  extend Shareable

  before do
    @file = nil  # you need to define this!
    @key = nil   # <- do nothing with this.
    @nums = (1..20).to_a  # define scan numbers
  end

  def key
    @key || @key = YAML.load_file(@file + '.key.yml')
  end

  def hash_match(hash, obj)
    #$DEBUG = 1
    puts "SCAN: #{obj.num}" if $DEBUG && obj.respond_to?(:num)
    hash.each do |k,v|
      if v.is_a?(Hash)
        hash_match(v, obj.send(k.to_sym))
      else
        puts "#{k}: #{v} but was #{obj.send(k.to_sym)}" if obj.send(k.to_sym) != v
        obj.send(k.to_sym).must_equal v
      end
    end
  end

  it 'reads header information' do
    Ms::Msrun.open(@file) do |ms|
      key['header'].each do |k,v|
        #puts "K: #{k} Vexp: #{v} Vact: #{ms.send(k.to_sym)}"
        ms.send(k.to_sym).must_equal v
      end
    end
  end

  it 'can access random scans' do
    Ms::Msrun.open(@file) do |ms|
      scan = ms.scan(20)
      hash_match(key['scans'][20], scan)
    end
  end

  it 'can read all scans' do
    num_required_scans = key['scans'].size
    Ms::Msrun.open(@file) do |ms|
      ms.each do |scan|
        if hash = key['scans'][scan.num]
          hash_match(hash, scan)
          num_required_scans -= 1
        end
      end
    end
    num_required_scans.must_equal 0
  end

  it 'can read scans of a certain ms_level' do
    nums = [1,5,9,13,17]
    Ms::Msrun.open(@file) do |ms|
      ms.each(:ms_level => 1) do |scan|
        scan.num.must_equal nums.shift 
      end
    end
    nums = [2,3,4,6,7,8,10,11,12,14,15,16,18,19,20]
    Ms::Msrun.foreach(@file, :ms_level => 2) do |scan|
      scan.num.must_equal nums.shift 
    end
  end

  it 'can avoid reading spectra' do 
    nums = @nums.map
    Ms::Msrun.foreach(@file, :spectrum => false) do |scan|
      assert scan.spectrum.nil?
      scan.num.must_equal nums.shift
    end
  end

  it 'can avoid reading precursor information' do 
    Ms::Msrun.foreach(@file, :precursor => false) do |scan|
      assert scan.precursor.nil?
    end
  end

  it 'gives scan counts for different ms levels' do
    Ms::Msrun.open(@file) do |ms|
      key['scan_count'].each do |index, count|
        ms.scan_count(index).must_equal count
      end
    end
  end

  it 'gives start and end mz even if the information is not given' do
    Ms::Msrun.open(@file) do |ms|
      ms.start_and_end_mz_brute_force.must_equal(key['start_and_end_mz'][1])
    end
  end

end

class Mzxml_v1 < MiniTest::Spec
  include MsrunSpec
  before do
    super
    @file = TESTFILES + '/opd1/000.v1.mzXML'
  end

  it 'can give start and end mz' do
    # scan has attributes startMz endMz
    Ms::Msrun.open(@file) do |ms|
      #ms.start_and_end_mz.must_equal([300.0, 1500.0])
      ms.start_and_end_mz.must_equal(key['start_and_end_mz'][1])
    end
  end
end

class Mzxml_v2_0 < MiniTest::Spec
  include MsrunSpec
  before do
    super
    @file = TESTFILES + '/opd1/020.v2.0.readw.mzXML'
  end
end

class Mzxml_v2_1 < MiniTest::Spec
  include MsrunSpec
  before do
    super
    @file = TESTFILES + '/opd1/000.v2.1.mzXML'
  end

  it 'gives nil if scans do not have start and end mz info' do
    # scans do not have startMz endMz or filterLine
    Ms::Msrun.open(@file) do |ms|
      ms.start_and_end_mz.must_equal([nil, nil])
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
      ms.start_and_end_mz.must_equal([300.0, 1500.0])
    end
    File.unlink(newname) if File.exist?(newname)
  end

end

