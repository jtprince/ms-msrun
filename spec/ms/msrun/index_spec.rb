require 'spec_helper'

require 'ms/msrun/index'

# those that behave_like should define:
# @id_list, @first_word, @last_word, @header_length
shared 'an Ms::Msrun::Index' do

  it 'is an array of doublets of byte and length' do
    @id_list.zip(@index) do |id_string, pair|
      string = IO.read(@file, pair.last, pair.first).strip
      string.matches id_string
      words = string.split(' ')
      words.first.is @first_word
      words.last.matches @last_word
      ok string.include?(id_string)
    end
  end
  it 'gives ids' do
    @id_list.enums @index.ids
  end
  it 'is enumerable' do
    # some nonsense showing that each_cons works (hence enumberable)
    reply = @index.each_cons(3).map {|pairs| [pairs.first, pairs.last] }
    reply.size.is( @index.length - 2 )
    reply.first.size.is 2
  end
  # minimal/frozen test
  it 'gives header length' do
    @index.header_length.is @header_length  # frozen
  end
  it 'can access by integer scan number' do
    @scan_nums.zip(@index) do |scan_num, pair|
      @index.scan(scan_num).is pair
    end
  end

 end

describe "an Ms::Msrun::Index" do
  it 'requires a file to create without subclass' do
    # Meaning, to construct an Ms::Msrun::Index that is blank, you need to
    # choose either an Mzxml or Mzml class (e.g.,  Ms::Msrun::Index::Mzml)
    lambda { x = Ms::Msrun::Index.new }.should.raise(ArgumentError)
  end
end

shared 'an Ms::Msrun::Index::Mzxml' do
  it 'has the right scan numbers' do
    @id_list.zip(@index) do |id_string, pair|
      string = IO.read(@file, pair.last, pair.first).strip
      ok string.include?(%Q{num="#{id_string}"})
    end
  end
  it 'gives the header length' do
    ok (!IO.read(@file, @index.header_length).match(/<scan /))
    IO.read(@file, @index.header_length + 6).matches /<scan /
  end

  behaves_like 'an Ms::Msrun::Index'
end

shared 'an Ms::Msrun::Index::Mzml' do
  behaves_like 'an Ms::Msrun::Index'
end

files = {
  'opd1/000.v1' => {:version => '1', :header_length => 824, :num_scans => 20},
  'opd1/020.v2.0.readw' => {:version => '2.0', :header_length => 1147, :num_scans => 20},
  'opd1/000.v2.1' => {:version => '2.1', :header_length => 1138, :num_scans => 20},
  'J/j24' => {:version => '3.1', :header_length => 1041, :num_scans => 24},
}

files.each do |file, data|
  describe "an Ms::Msrun::Index for mzXML v#{data[:version]}" do
    before do 
      @file = TESTFILES + '/' + file + '.mzXML'
      @index = Ms::Msrun::Index.new(@file)
      @scan_nums = (1..(data[:num_scans])).to_a
      @id_list = @scan_nums.map(&:to_s)
      @first_word = "<scan"
      @last_word = %r{</scan>|</msRun>|</peaks>}
      @header_length = data[:header_length]
    end
    behaves_like 'an Ms::Msrun::Index::Mzxml'
  end
end

files = {
  'J/j24' => {:version => '1.1', :header_length => 1041, :num_scans => 24},
}
files.each do |file, data|
  describe "an Ms::Msrun::Index for mzML v#{data[:version]}" do
    before do
      @file = TESTFILES + '/' + file + '.mzML'
      @index = Ms::Msrun::Index.new(@file)
      @scan_nums = (1..(data[:num_scans])).to_a
      @id_list = @scan_nums.map {|v| "controllerType=0 controllerNumber=1 scan=#{v}" }
      @first_word = "<spectrum"
      @last_word = "</spectrum>"
      @header_length = data[:header_length]
    end
    behaves_like 'an Ms::Msrun::Index::Mzml'
  end
end

xdescribe 'an Ms::Msrun::Index from an unindexed mzML file' do
  before do
    @file = TESTFILES + '/openms/saved.mzML'
  end
  behaves_like 'an Ms::Msrun::Index'
  # TODO: MORE??
end

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
