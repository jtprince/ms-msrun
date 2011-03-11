
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

  # returns a Ms::Scan object for the scan at that number
  def scan(num, parse_opts={})
    i = index.scan(num)
    @parser.parse_scan(i[0], i[1], parse_opts)
  end

    # returns each scan
    # options:
    #     :spectrum => true | false (default is true)
    #     :precursor => true | false (default is true)
    #     :ms_level => Integer or Array return only scans of that level
    #     :reverse => true | false (default is false) goes backwards
    def each_scan(parse_opts={}, &block)
      ms_levels = 
        if msl = parse_opts[:ms_level]
          if msl.is_a?(Integer) ; [msl]
          else ; msl  
          end
        end
      snums = index.scan_nums
      snums = snums.reverse if parse_opts[:reverse]
      snums.each do |scan_num|
        if ms_levels
          next unless ms_levels.include?(get_ms_level(scan_num))
        end
        block.call(scan(scan_num, parse_opts))
      end
    end

    


end
