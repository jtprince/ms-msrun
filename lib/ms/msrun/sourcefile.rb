require 'cv'

module Ms
  class Msrun
    class Sourcefile   
      attr_accessor :cv_description

      def initialize(id, name="", location="")
        (@id, @name, @location) = [id, name, location]
      end

      # this is just suggestive of how to do it, not tested yet
      def to_mzml(xml)
        xml.sourceFile(:id => id, :name => name, :location => location) { cv_description.to_xml(xml) }
      end
    end
  end
end
