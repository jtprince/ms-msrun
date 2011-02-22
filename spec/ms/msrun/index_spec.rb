require 'spec_helper'

require 'ms/msrun/index'

describe "MsMsrun" do
  it "fails" do
    'happy'.is 'happy'
    dorky = 'sunshine'
    dorky.is 'sunshine'
    'dorky'.is 'happy'
  end
end

=begin
shared 'an Ms::Msrun::Index' do

  # those that behave_like should define:
  # @id_list, @first_word, @last_word, @header_length
  before do
    @index = Ms::Msrun::Index.new(@file)
  end

  it 'is an array of doublets of byte and length' do
    @id_list.zip(@index) do |pair, id_string|
      string.matches id_string
      string = IO.read(file, pair.last, pair.first).strip
      words = string.split(' ')
      words.first.is @first_word
      words.last.matches @last_word
      string.should.match id_string
    end
  end

  xit 'gives scan_nums' do
    @indices.each do |index|
      index.scan_nums.is((1..20).to_a)
    end
  end

  xit 'is enumerable' do
    @indices.each do |index|
      scan_nums = index.scan_nums
      index.each_with_index do |doublet,i|
        index[scan_nums[i]].is doublet
      end
    end
  end

  it 'gives header length' do
    @index.header_length.is @header_length
    header_lengths = [824, 1138, 1147]
    @indices.zip(@files, header_lengths) do |index, file, header_length|
      index.header_length.is header_length
    end
  end
end

describe "an Ms::Msrun::Index" do
  it 'requires a file to create without subclass' do
    lambda { x = Ms::Msrun::Index.new }.should.raise(ArgumentError)
  end
end

describe "an Ms::Msrun::Index for mzXML v1" do
  before do 
    @file = "#{TESTFILES}/opd1/000.v1.mzXML"
    @id_list = (1..20).map(&:to_s)
    @first_word = "<scan"
    @last_word = %r{</scan>|</msRun>|</peaks>}
  end
  behaves_like 'an Ms::Msrun::Index'
end

=end


=begin
opd_files = %w(000.v1 020.v2.0.readw 000.v2.1).map {|v| TESTFILES + '/opd1/' + v + '.mzXML' }
j_files = *%w(j24z).map {|v| TESTFILES + '/J/' + v + '.mzXML' }
files = opd_files + j_files
versions = %w(1 2.0 2.1 3.1)
files.zip(versions) do |file, version|
  describe "an Ms::Msrun::Index for mzXML v#{version}" do
    before do 
      @file = file
      @id_list = (1..20).map(&:to_s)
      @first_word = "<scan"
      @last_word = %r{</scan>|</msRun>|</peaks>}
    end
    behaves_like 'an Ms::Msrun::Index'
  end
end
=end

=begin
xdescribe 'an Ms::Msrun::Index from an mzML file' do
  before do
    @file = TESTFILES + '/J/j24z.mzML'
  end
  behaves_like 'an Ms::Msrun::Index'
end

xdescribe 'an Ms::Msrun::Index from an unindexed mzML file' do
  before do
    @file = TESTFILES + '/openms/saved.mzML'
  end
  behaves_like 'an Ms::Msrun::Index'
  # TODO: MORE??
end
=end

=begin
    index.scan_nums.enums [5435, 5436, 5437]  # <- will deprecate this behavior in future
    File.open(file) do |io|
      cnt = 0
      index.each do |start, len|
        string = (io.pos = start) && io.read(len)
        string.matches %r{^<spectrum }
        string.matches %r{</spectrum>\s*}
        string["scan=#{index.scan_nums[cnt]}"]
        cnt += 1
      end
    end
  end
=end
