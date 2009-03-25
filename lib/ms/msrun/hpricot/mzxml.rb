
require 'ms/msrun'
require 'ms/precursor'
require 'hpricot'

module Ms
  class Msrun
    module Hpricot
    end
  end
end

class Ms::Msrun::Hpricot::Mzxml
  NetworkOrder = true

  # note that the string may contain a trailing end scan node or may be
  # missing its terminating node!
  # version is a string
  # returns a Ms::Scan object
  def self.parse_scan(string, version)
    doc = Hpricot.XML(string)
    p doc.at("/scan").attr
  end


end


