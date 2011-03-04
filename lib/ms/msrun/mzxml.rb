
require 'ms/spectrum'
require 'ms/data'
require 'ms/data/lazy_io'
require 'ms/msrun'
require 'libxml'

module Ms ; end
module Ms::Msrun ; end

class Ms::Msrun::Mzxml
  include Msrun
  def scan_nums
    index.scan_nums
  end

  # creates the parser and sets it as an instance variable
  def create_parser(io)
    @parser = Ms::Msrun::Mzxml::Parser.new(self, io)
  end

end
