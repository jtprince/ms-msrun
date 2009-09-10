require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'rexml/document'
require 'ms/msrun/index'

class MsMsrunIndexSpec < MiniTest::Spec

  def initialize(*args)
    @files = %w(000.v1.mzXML 000.v2.1.mzXML 020.v2.0.readw.mzXML).map {|v| TESTFILES + '/opd1/' + v }
    super *args
  end

  it 'returns an index that points to scans' do
    @files.each do |file|
      index = Ms::Msrun::Index.new(file)
      index.each_with_index do |pair,i|
        string = IO.read(file, pair.last, pair.first).strip
        string[0,5].must_equal '<scan'
        string[-7..-1].must_match %r{</scan>|/peaks>|/msRun>}
        string.must_match %r{num="#{i+1}"}
      end
    end
  end

end
