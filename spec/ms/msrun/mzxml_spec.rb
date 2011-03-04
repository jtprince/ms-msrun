
describe 'an Ms::Msrun::Mzxml object' do
  behaves_like 'an Ms::Msrun'

   it 'can access random scans' do
      Ms::Msrun.open(@file) do |ms|
        scan = ms.scan(@random_scan_num)
        hash_match(@key['scans'][@random_scan_num], scan)
      end
    end



end
