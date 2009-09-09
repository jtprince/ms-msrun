require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'ms/msrun/index'

class IndexSpec < MiniTest::Spec

  def initialize(*args)
    @files = %w(000.v1.mzXML 000.v2.1.mzXML 020.v2.0.readw.mzXML).map {|v| TESTFILES + '/opd1/' + v }
    super *args
  end

  it 'works' do
    first = @files.first
    index = Ms::Msrun::Index.index(first)
    index.each do |pair|
      first
    end
    scan1 = index[1]
    scan2 = index[2]
    scan3 = index[3]
    #puts IO.read(first, scan1.last, scan1.first)
    #puts IO.read(first, scan2.last, scan2.first)
    i = 6
    puts IO.read(first, index[i].last, index[i].first)

  end

end
