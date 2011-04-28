require 'spec_helper.rb'
require 'ms/msrun'

require 'yaml'

module MsrunSpec

  before_all = lambda do |file|
    key = YAML.load_file(file + '.key.yml')
    nums = (1..key['scan_count'][0]).to_a  # define scan numbers
    [key, nums]
  end

  shared 'an Ms::Msrun' do

    def hash_match(hash, obj)
      hash.each do |k,v|
        if v.is_a?(Hash)
          hash_match(v, obj.send(k))
        else
          puts("#{k} -> expecting: #{v.inspect} actual:#{obj.send(k).inspect}") unless obj.send(k) == v
          obj.send(k).is v
        end
      end
    end

    it 'reads header information' do
      Ms::Msrun.open(@file) do |ms|
        hash_match(@key['header'], ms)
      end
    end

    xit 'can access random spectra' do
    end

    xit 'can access random scans' do
      scans = @key['scans']
      random_scan_num = scans.keys[1] # will choose the second scan in the list of scans as 'random'
      Ms::Msrun.open(@file) do |ms|
        scan = ms.scan(random_scan_num)
        hash_match(scans[random_scan_num], scan)
      end
    end

    xit 'can read all scans' do
      num_required_scans = @key['scans'].size
      Ms::Msrun.open(@file) do |ms|
        ms.each_scan do |scan|
          if hash = @key['scans'][scan.num]
            hash_match(hash, scan)
            num_required_scans -= 1
          end
        end
      end
      num_required_scans.is 0
    end

    xit 'can read scans of a certain ms_level' do
      # this needs to BE REWRITTEN TO use the ms_levels key/value in the
      # key!!!!!
      nums = [1,7,13,19] if @file.include? "j24"
      temp = nums.dup

      Ms::Msrun.open(@file) do |ms|
        ms.each_scan(:ms_level => 1) do |scan|
          break if scan.num > nums.last && !@file.include?("j24")
          scan.num.is temp.shift 
        end
      end

      nums = (1..24).to_a - nums
      Ms::Msrun.open(@file) do |ms|
        ms.each_scan(@file, :ms_level => 2) do |scan|
          break if scan.num > 20 && !@file.include?("j24")
          scan.num.is nums.shift 
        end
      end
    end

    xit 'can avoid reading spectra' do 
      nums = @nums.dup
      Ms::Msrun.foreach(@file, :spectrum => false) do |scan|
        scan.spectrum.nil?.ok
        scan.num.is nums.shift
      end
    end

    xit 'can avoid reading precursor information' do 
      Ms::Msrun.foreach(@file, :precursor => false) do |scan|
        scan.precursor.nil?.ok
      end
    end

    xit 'gives scan counts for different ms levels' do
      Ms::Msrun.open(@file) do |ms|
        @key['scan_count'].each do |index, count|
          ms.scan_count(index).is count
        end
      end
    end
  end

end


