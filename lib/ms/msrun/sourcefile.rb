require 'andand'
require 'cv'

module Ms
  module Msrun
    class Sourcefile   
      OS_SAFE_PATH_SPLIT = /[\/\\]/o
      REMOTE_LOCATION_RE = %r{^(\w+)://(.*?)(/.*)}
      LOCAL_URI_RE = %r{^(\w+)://(.*)}

      # takes a full file name and returns a valid Sourcefile object
      # (robust to different OS's)
      def self.from_local_fullpath(id, fullpathname)
        pieces = fullpathname.split(OS_SAFE_PATH_SPLIT)
        self.new(id, pieces.last, ("file://" + pieces[0...-1].join('/')))
      end

      # sets the id to be the sha1sum and creates a cv params for the sha1
      def self.from_mzxml(filename, sha1)
        obj = self.new(sha1, filename)
        obj.cv_description = [Cv::Param.new('MS', "MS:1000569", 'SHA-1', sha1)]
        # consider grabbing the fileType??
        obj 
      end

      # an identifier for the file
      attr_accessor :id
      # Name of the source file, without reference to location (either URI or local path).
      # so, this may end up being a complete URI, and if it uses the file
      # protocol, it may end up holding the location information somewhat
      # inadvertently.  valid examples: "myfile.raw", "file://path/to/myfile.raw"
      attr_accessor :name
      # URI-formatted location where the file was retrieved.
      # file://path/to/file
      attr_accessor :location
      # a Cv::Description object
      attr_accessor :cv_description

      # name and location should be nil if they are an empty string in xml
      def initialize(id, name=nil, location=nil)
        (@id, @name, @location) = [id, name, location]
      end

      # the filename stripped of any location information
      def basename
        @name.split(OS_SAFE_PATH_SPLIT).last
      end

      # the filename stripped of any location information and without extension
      def basename_noext
        bn = basename
        bn.chomp(File.extname(bn))
      end

      # returns the full uri (including the filename) of the file
      def full_uri
        if name_is_uri?  # assume name is alread a URI
          name
        else
          (location[-1,1] == '/') ? (location + name) : location + '/' + name
        end
      end

      # returns the protocol for retrieving the location of the file (e.g.,
      # 'file' or 'http')
      def protocol
        if name_is_uri?
          @name.match(REMOTE_LOCATION_RE).andand[1]
        else
          @location.match(LOCAL_URI_RE).andand[1]
        end
      end

      # the computer hosting the file, derived from the name attribute if it
      # is a uri, otherwise nil
      # unspecified
      def host
        if name_is_uri?
          @name.match(REMOTE_LOCATION_RE).andand[2] 
        else ; nil
        end
      end

      # if the location is nil, the name is treated as a uri
      def name_is_uri?
        @location.nil?
      end

      # uri path to the file.  So, no protocol and no host given (if the name
      # is a URI), but just the path to the directory holding the file
      def dirname
        if name_is_uri? 
          dn = @name.match(REMOTE_LOCATION_RE).andand[3] 
          dn.split('/')[0...-1].join('/')
        else
          dn = @location.match(LOCAL_URI_RE).andand[2]
          dn.match(%r{^/[A-Za-z]:/}) ? dn[1..-1] : dn
        end
      end

      # this is just suggestive of how to do it, not tested yet
      def to_mzml(xml)
        xml.sourceFile(:id => id, :name => name, :location => location) { cv_description.to_xml(xml) }
      end
    end
  end
end
