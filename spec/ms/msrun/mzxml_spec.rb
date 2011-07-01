require 'spec_helper'

require 'ms/msrun_spec'

require 'yaml'

shared 'an Ms::Msrun::Mzxml' do
  behaves_like 'an Ms::Msrun'
end

files = {
  '/opd1/000.v1.mzXML' => ['v1'],
#  '/opd1/020.v2.0.readw.mzXML' => ['v2.0'],
#  '/opd1/000.v2.1.mzXML' => ['v2.1'],
#  '/J/j24.mzXML' => ['v3.1'],
#  '/J/j24z.mzXML' => ['v3.1 with compressed peaks'],
#  '/openms/test_set.mzXML' => ['v2.1 unindexed'],
}

files.each do |filename, data_ar|
  describe "reading an mzXML #{data_ar[0]}" do
    @file = TESTFILES + filename
    @key = YAML.load_file(@file + '.key.yml')
    behaves_like 'an Ms::Msrun::Mzxml'
  end
end
