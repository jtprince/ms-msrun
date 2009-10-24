require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

require 'ms/msrun'

module MsrunSpec
  extend Shareable

  before do
    @file = nil  # you need to define this!
    @key = nil   # <- do nothing with this.
  end

  def key
    @key || @key = YAML.load_file(@file + '.key.yml')
  end

  def hash_match(hash, obj)
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
    total = (1..20).to_a.inject(0) {|sum,v| sum + v }
    Ms::Msrun.open(@file) do |ms|
      ms.each do |scan|
        # do something with your scan
        total -= scan.num
      end
    end
    total.must_equal 0
  end

  working here 
  ################ WORKING HERE!
  #it 'can avoid reading spectrum' do 
  #  Ms::Msrun.foreach(@file) do |scan|  # <- like IO.foreach 
  #  end
  #end

  #it 'can just read ms_level' do
  #end
end

class Mzxml_v1 < MiniTest::Spec
  include MsrunSpec
  before do
    super
    @file = TESTFILES + '/opd1/000.v1.mzXML'
  end
end

#class Mzxml_v2_0 < MiniTest::Spec
  #include MsrunSpec
  #before do
    #super
    #@file = TESTFILES + '/opd1/020.v2.0.readw.mzXML'
  #end
#end

#class Mzxml_v2_1 < MiniTest::Spec
  #include MsrunSpec
  #before do
    #super
    #@file = TESTFILES + '/opd1/000.v2.1.mzXML'
  #end
#end

