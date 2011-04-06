require 'spec_helper'

require 'ms/msrun/index_spec'
require 'ms/msrun/index/mzml'

describe 'an Ms::Msrun::Index::Mzxml class on an unindexed file' do
  before do
    @file = TESTFILES + '/openms/saved.mzML'
    @klass = Ms::Msrun::Index::Mzml
    @has_index = false
  end
  behaves_like 'an Ms::Msrun::Index subclass'
end

files = {
  'J/j24' => {:version => '1.1', :header_length => 1041, :num_scans => 24},
}
files.each do |file, data|
  describe "an Ms::Msrun::Index for scans for mzML v#{data[:version]}" do
    before do
      @file = TESTFILES + '/' + file + '.mzML'
      @io = File.open(@file)
      @index_list = Ms::Msrun::Index.index_list(@io)
      @index = @index_list.first
      @scan_nums = (1..(data[:num_scans])).to_a
      @id_list = @scan_nums.map {|v| "controllerType=0 controllerNumber=1 scan=#{v}" }
      @first_word = "<spectrum"
      @last_word = "</spectrum>"
      @header_length = data[:header_length]
    end
    after do
      @io.close
    end
    it 'is named' do
      p @index.name 
      1.is 1
    end
    behaves_like 'an Ms::Msrun::Index'
  end
end


