#!/usr/bin/ruby

require 'nokogiri'

class MyDoc < Nokogiri::XML::SAX::Document
  def initialize(io)
    @io = io 
  end

  def start_element( name, attributes = [])
    puts "NAME: #{name}"
    puts "POST: "
    puts @io.pos
  end

end

File.open("test3.xml") do |io|
  parser = Nokogiri::XML::SAX::PushParser.new( MyDoc.new(io) )
  io.each_line do |line|
    parser << line
  end
end

#xml = Nokogiri::XML.parse(IO.read("test3.xml"), nil, nil,  Nokogiri::XML::ParseOptions::DEFAULT_XML | Nokogiri::XML::ParseOptions::NOBLANKS )
