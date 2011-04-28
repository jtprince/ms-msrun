
require 'spec_helper'
require 'ms/msrun_spec'

shared 'an Ms::Msrun::Mzml' do
  behaves_like 'an Ms::Msrun'
end

describe 'reading an mzML file' do
  @file = TESTFILES + '/J/j24.mzML'
  @key = YAML.load_file(@file + '.key.yml')
  behaves_like 'an Ms::Msrun::Mzml'
end

xdescribe 'reading a compressed mzML file' do
  @file = TESTFILES + '/J/j24z.mzML'
  @key = YAML.load_file(@file + '.key.yml')
  behaves_like 'an Ms::Msrun::Mzml'
end

xdescribe 'reading a short stubby mzML file written by openms toppview' do
  @file = TESTFILES + '/openms/saved.mzML'
  @key = YAML.load_file(@file + '.key.yml')
  behaves_like 'an Ms::Msrun::Mzml'
end

