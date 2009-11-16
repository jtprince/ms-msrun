require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'rexml/document'
require 'ms/msrun/index'


describe 'an Ms::Msrun::Index' do

  @files = %w(000.v1.mzXML 000.v2.1.mzXML 020.v2.0.readw.mzXML).map {|v| TESTFILES + '/opd1/' + v }

  before do
    @indices = @files.map do |file|
      indices = Ms::Msrun::Index.new(file)
    end
  end


  it 'is indexed by scan num and gives doublets of byte and length' do
    @files.zip(@indices) do |file, index|
      index.each_with_index do |pair,i|
        string = IO.read(file, pair.last, pair.first).strip
        string[0,5].is '<scan'
        string[-7..-1].should.match %r{</scan>|/peaks>|/msRun>}
        string.should.match %r{num="#{i+1}"}
      end
    end
  end

  it 'gives scan_nums' do
    @indices.each do |index|
      index.scan_nums.is((1..20).to_a)
    end
  end

  it 'is enumerable' do
    @indices.each do |index|
      scan_nums = index.scan_nums
      index.each_with_index do |doublet,i|
        index[scan_nums[i]].is doublet
      end
    end
  end

  it 'gives header length' do
    header_lengths = [824, 1138, 1147]
    @indices.zip(@files, header_lengths) do |index, file, header_length|
      index.header_length.is header_length
    end
  end

  it 'gives a scan for #first and #last' do
    # TODO: fill in with actual data too
    @indices.each do |index|
      ok !index.first.nil?
      ok !index.last.nil?
    end
  end

end
