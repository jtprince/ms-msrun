require 'spec_helper'
require 'ms/msrun/index_spec'

require 'ms/msrun/index/mzxml'

describe 'an Ms::Msrun::Index::Mzxml class on an indexless file' do
  before do
    @klass = Ms::Msrun::Index::Mzxml
    @file = TESTFILES + '/openms/test_set.mzXML'
    @has_index = false
  end
  behaves_like 'an Ms::Msrun::Index subclass'
end

describe 'an Ms::Msrun::Index::Mzxml class on an indexed file' do
  before do
    @klass = Ms::Msrun::Index::Mzxml
    @file = TESTFILES + '/J/j24.mzXML'
    @has_index = true
  end
  behaves_like 'an Ms::Msrun::Index subclass'
end

shared 'an Ms::Msrun::Index::Mzxml' do
  behaves_like 'an Ms::Msrun::Index'
  it 'has the right scan numbers' do
    p @id_list
    @id_list.zip(@index) do |id_string, pair|
      string = IO.read(@file, pair.last, pair.first).strip
      ok string.include?(%Q{num="#{id_string}"})
    end
  end

  it 'gives the header length' do
    ok (!IO.read(@file, @index.header_length).match(/<scan /))
    IO.read(@file, @index.header_length + 6).matches /<scan /
  end
end

files = {
 # 'opd1/000.v1' => {:version => '1', :header_length => 824, :num_scans => 20, :indexed => true},
 # 'opd1/020.v2.0.readw' => {:version => '2.0', :header_length => 1147, :num_scans => 20, :indexed => true},
 # 'opd1/000.v2.1' => {:version => '2.1', :header_length => 1138, :num_scans => 20, :indexed => true},
 # 'J/j24' => {:version => '3.1', :header_length => 1041, :num_scans => 24, :indexed => true},
 'openms/test_set' => {:version => '2.1', :header_length => 1041, :num_scans => 64, :indexed => false},
}

files.each do |file, data|
  describe "an Ms::Msrun::Index for mzXML v#{data[:version]}" do
    before do 
      @file = TESTFILES + '/' + file + '.mzXML'
      # we won't usually call it this way, but we can
      # usually called as a list Ms::Msrun::List.new(@file).first
      @index = Ms::Msrun::Index::Mzxml.new(@file)
      @scan_nums = (1..(data[:num_scans])).to_a
      @id_list = @scan_nums.map(&:to_s)
      @first_word = "<scan"
      @last_word = %r{</scan>|</msRun>|</peaks>}
      @header_length = data[:header_length]
    end
    behaves_like 'an Ms::Msrun::Index::Mzxml'
  end
end

