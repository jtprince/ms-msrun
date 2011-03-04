
module Ms
  class Spectrum
    attr_accessor :scans

    # retrieve the first scan associated with this spectrum
    def scan ; scans[0] end
    # set the first scan associated with this spectrum
    def scan=(scn) ; scans[0]=scn end

  end
end
