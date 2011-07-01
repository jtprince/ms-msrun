
require 'nokogiri'
require 'ms/msrun/nokogiri'
require 'ms/msrun'
require 'ms/msrun/sourcefile'
require 'ms/spectrum'
require 'ms/data'
require 'ms/data/lazy_io'
require 'ms/precursor'
require 'andand'

module Ms ; end
module Ms::Msrun ; end

module Ms::Msrun::Parser
  def initialize(msrun_object, io)
    @msrun = msrun_object
    @io = io
    @version = @msrun.version
  end
end
