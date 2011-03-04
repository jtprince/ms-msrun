
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


