
require 'ms/spectrum'
require 'ms/data'
require 'ms/data/lazy_io'
require 'ms/msrun'

module Ms ; end
module Ms::Msrun ; end

class Ms::Msrun::Mzml
  include ::Ms::Msrun

  # creates the parser and sets it as an instance variable
  def create_parser(io)
    @parser = Ms::Msrun::Mzml::Parser.new(self, io)
  end

  # returns each scan
  # options:
  #     :spectrum => true | false (default is true)
  #     :precursor => true | false (default is true)
  #     :ms_level => Integer or Array return only scans of that level
  #     :reverse => true | false (default is false) goes backwards
  def each_spectrum(parse_opts={}, &block)
    ms_levels = 
      if msl = parse_opts[:ms_level]
        if msl.is_a?(Integer) ; [msl]
        else ; msl  
        end
      end
    snums = index.ids
    snums = snums.reverse if parse_opts[:reverse]
    snums.each do |scan_num|
      if ms_levels
        next unless ms_levels.include?(get_ms_level(scan_num))
      end
      block.call(scan(scan_num, parse_opts))
    end
  end




end
