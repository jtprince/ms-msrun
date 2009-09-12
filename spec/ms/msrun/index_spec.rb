require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'rexml/document'
require 'ms/msrun/index'

class MsMsrunIndexSpec < MiniTest::Spec

  before do
    @indices = @files.map do |file|
      indices = Ms::Msrun::Index.new(file)
    end
  end

  def initialize(*args)
    @files = %w(000.v1.mzXML 000.v2.1.mzXML 020.v2.0.readw.mzXML).map {|v| TESTFILES + '/opd1/' + v }
    super *args
  end

  it 'is indexed by scan num and gives doublets of byte and length' do
    @files.zip(@indices) do |file, index|
      index.each_with_index do |pair,i|
        string = IO.read(file, pair.last, pair.first).strip
        string[0,5].must_equal '<scan'
        string[-7..-1].must_match %r{</scan>|/peaks>|/msRun>}
        string.must_match %r{num="#{i+1}"}
      end
    end
  end

  it 'gives scan_nums' do
    @indices.each do |index|
      index.scan_nums.must_equal((1..20).to_a)
    end
  end

  it 'is enumerable' do
    @indices.each do |index|
      scan_nums = index.scan_nums
      index.each_with_index do |doublet,i|
        index[scan_nums[i]].must_equal doublet
      end
    end
  end

  it 'gives header length' do
    header_lengths = [824, 1138, 1147]
    @indices.zip(@files, header_lengths) do |index, file, header_length|
      index.header_length.must_equal header_length
    end
  end

  it 'gives a scan for #first and #last' do
    # TODO: fill in with actual data too
    @indices.each do |index|
      index.first.wont_equal nil
      index.last.wont_equal nil
    end
  end

end
