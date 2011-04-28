require 'spec_helper'

require 'ms/msrun/index_spec'
require 'ms/msrun/index/mzml'

describe 'an Ms::Msrun::Index::Mzxml class on an unindexed file' do
  before do
    @file = TESTFILES + '/openms/saved.mzML'
    @klass = Ms::Msrun::Index::Mzml
    @has_index = false
    @names = [:spectrum]
  end
  behaves_like 'an Ms::Msrun::Index subclass'
end

describe 'an Ms::Msrun::Index::Mzxml class on an indexed file' do
  before do
    @file = TESTFILES + '/J/j24.mzML'
    @klass = Ms::Msrun::Index::Mzml
    @has_index = true
    @names = [:spectrum, :chromatogram]
  end
  behaves_like 'an Ms::Msrun::Index subclass'
end

files = {
  'J/j24' => {:version => '1.1', :header_length => 1041, :num_scans => 24},
}
files.each do |file, data|
  describe "an Ms::Msrun::Index spectra index for mzML v#{data[:version]}" do
    before do
      @file = TESTFILES + '/' + file + '.mzML'
      @io = File.open(@file)
      @index_list = Ms::Msrun::Index.index_list(@io)
      @index = @index_list.first
      @scan_nums = (1..(data[:num_scans])).to_a
      @id_list = @scan_nums.map {|v| "controllerType=0 controllerNumber=1 scan=#{v}" }
      @first_word = "<spectrum"
      # the last scan's length goes too far because it is based on the
      # location of the index
      @last_word = %r{</(spectrum|mzML)>}
      @header_length = data[:header_length]
    end
    after do
      @io.close
    end

    it 'is named' do
      @index.name.is :spectrum
    end
    behaves_like 'an Ms::Msrun::Index'
  end
end


