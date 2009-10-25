

module Ms
  class Msrun
    module Nokogiri
      NOBLANKS = ::Nokogiri::XML::ParseOptions::DEFAULT_XML | ::Nokogiri::XML::ParseOptions::NOBLANKS
      PARSER_ARGS = [nil,nil,NOBLANKS]
    end
  end
end


