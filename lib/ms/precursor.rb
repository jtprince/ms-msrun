
module Ms
  # charge_states are the possible charge states of the precursor
  # parent references a scan
  PrecursorAtts = [:mz, :intensity, :parent, :charge_states]
end

Ms::Precursor = Struct.new(*Ms::PrecursorAtts)

class Ms::Precursor

  undef :intensity
  
  def intensity
    if self[1].nil?
      if s = self[2].spectrum
        self[1] = s.intensity_at_mz(self[0])
      else
        nil   # if we didn't read in the spectra, we can't get this value!
      end
    end
    self[1]
  end

  alias_method :inten, :intensity

end
