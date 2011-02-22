require 'spec_helper'

require 'ms/msrun/sha1'

describe 'sha1 creation from mzXML' do
  @files = %w(000.v1.mzXML 020.v2.0.readw.mzXML 000.v2.1.mzXML).map do |file|
    TESTFILES + "/opd1/#{file}"
  end

  ## NOTE: this does NOT match up to real files yet!
  xit 'can determine a sha1 for an mzxml file' do
    @files.each do |file|
      (actual, recorded) = Ms::Msrun::Sha1.digest_mzxml_file file
      [actual, recorded].each {|v| assert !v.nil? }
      actual.must_equal recorded
    end
  end


end
