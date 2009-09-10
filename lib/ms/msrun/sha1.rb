require 'digest/sha1'

module Ms
  class Msrun
    # the mzXML digest is from the start of the document to the end of the
    # first sha1 tag: '...<sha1>'
    module Sha1
      module_function

      # returns [calculated digest, recorded digest] for an mzXML file 
      def digest_mzxml_file(file)
        recorded_digest = nil

        incr_digest = ""
        #incr_digest = Digest::SHA1.new
        endpos = nil
        File.open(file, 'rb') do |io|
          while line = io.gets
            if line.include?("<sha1>")  
              incr_digest << line[0, line.index("<sha1>") + 6]
              if line =~ %r{<sha1>(.*)</sha1>}
                recorded_digest = $1.dup
                break
              else
                incr_digest << line
              end
            end
          end
        end

        [Digest::SHA1.hexdigest(incr_digest), recorded_digest]
        #[incr_digest.hexdigest, recorded_digest]
      end
    end
  end
end
