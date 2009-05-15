
require 'ms/spectrum'
require 'ms/data'
require 'ms/data/lazy_io'
require 'ms/msrun'
require 'ms/precursor'
require 'axml'

module Ms
  class Msrun
    module Axml
    end
  end
end

class Ms::Msrun::Axml::Mzxml
  NetworkOrder = true

  # version is a string
  def parse(msrun_obj, io, version)
    root = AXML.parse(io, :text_indices => 'peaks', :parser => :xmlparser)
    msrun_n = msrun_node(root, version)

    # The filename
    parent_n = msrun_n.find_first_child('parentFile')
    fn = parent_n['fileName']
    fn.gsub!(/\\/, '/')
    msrun_obj.parent_basename = File.basename(fn)
    dn = File.dirname(fn)
    dn = nil if dn == '.' && !fn.include?('/')
    msrun_obj.parent_location = dn

    ## HEADER
    scan_count = msrun_n['scanCount'].to_i
    msrun_obj.scan_count = scan_count

    scans_by_num = Array.new(scan_count + 1)

    ## SPECTRUM
    parent = nil
    scans = Array.new( scan_count )
    scn_index = 0

    if version >= '3.0'
      warn '[version 3.0 parsing may fail if > 1 peak list per scan]'
      # note that mzXML version 3.0 *can* have more than one peak...
      # I'm not sure how to deal with that since I have one spectrum/scan
    end

    scan_nodes = msrun_n.find_children('scan')
    add_scan_nodes(scan_nodes, scans, scn_index, scans_by_num, version, io)

    ## update the scan's parents
    Ms::Msrun.add_parent_scan(scans)

    # note that startTime and endTime are optional AND in >2.2 are dateTime
    # instead of duration types!, so we will just use scan times...
    # Also, note that startTime and endTime are BROKEN on readw -> mzXML 2.0
    # export.  They give the start and end time in seconds, but they are
    # really minutes.  All the more reason to use the first and last scans!
    msrun_obj.start_time = scans.first.time
    msrun_obj.end_time = scans.last.time
    msrun_obj.scans = scans
  end

  # takes a scan node and creates a scan object
  # the parent scan is the one directly above it in mslevel
  def create_scan(scan_n, scans_by_num, io=nil)
    scan = new_scan_from_node(scan_n)
    prec = nil
    scan_n.each do |node|
      case node.name
      when 'precursorMz'
        # should be able to do this!!!
        #scan[5] = scan_n.find('child::precursorMz').map do |prec_n|
        raise RuntimeError, "the msrun object can only handle one precursor!" unless prec.nil?
        prec = Ms::Precursor.new
        prec[1] = node['precursorIntensity'].to_f
        prec[0] = node.content.to_f
        if x = node['precursorScanNum']
          prec[2] = scans_by_num[x.to_i]
        end
      when 'peaks'
        # assumes that parsing was done with a LazyPeaks parser!
        nc = node.text
        data = Ms::Data::LazyIO.new(io, nc.first, nc.last, Ms::Data::LazyIO.unpack_code(node['precision'].to_i, NetworkOrder))
        scan[8] = Ms::Spectrum.new(Ms::Data::Interleaved.new(data))
      end
    end
    scan[7] = prec
    scan
  end


  # assumes that node contains scans and checks any scan nodes for children
  def add_scan_nodes(nodes, scans, scn_index, scans_by_num, version, io)
    nodes.each do |scan_n|
      scan = create_scan(scan_n, scans_by_num, io)
      #puts "scannum: "
      #p scan[0]
      scans[scn_index] = scan
      scans_by_num[scan[0]] = scan 
      scn_index += 1
      if version > '1.0'
        new_nodes = scan_n.find('child::scan')
        if new_nodes.size > 0
          scn_index = add_scan_nodes(new_nodes, scans, scn_index, scans_by_num, version, io)
        end
      end
    end
    scn_index
  end

  def msrun_node(node, version)
    if version >= '2.0' 
      kids = node.children.select {|v| v.name == 'msRun' }
      raise(NotImplementedError, "one msrun per doc right now" ) if kids.size > 1
      kids.first
    else
      node
    end
  end

  def new_scan_from_node(node)
    scan = Ms::Scan.new  # array class creates one with 9 positions
    scan[0] = node['num'].to_i
    scan[1] = node['msLevel'].to_i
    if x = node['retentionTime']
      scan[2] = x[2...-1].to_f
    end
    if x = node['startMz']
      scan[3] = x.to_f
      scan[4] = node['endMz'].to_f
      scan[5] = node['peaksCount'].to_i
      scan[6] = node['totIonCurrent'].to_f
    end
    scan
  end
end
