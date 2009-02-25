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

  it 'reads header information' do
    Ms::Msrun.open(@file) do |ms|
      key['header'].each do |k,v|
        ms.send(k.to_sym).must_equal v
      end
    end
  end

end

class Mzxml_v1 < MiniTest::Spec
  include MsrunSpec
  before do
    super
    @file = '/home/jtprince/ms-msrun/spec/files/opd1/000.v1.mzXML'
  end
end

class Mzxml_v2_0 < MiniTest::Spec
  include MsrunSpec
  before do
    super
    @file = '/home/jtprince/ms-msrun/spec/files/opd1/020.v2.0.readw.mzXML'
  end
end

class Mzxml_v2_1 < MiniTest::Spec
  include MsrunSpec
  before do
    super
    @file = '/home/jtprince/ms-msrun/spec/files/opd1/000.v2.1.mzXML'
  end
end

