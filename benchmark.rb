require "ms/msrun"

#Ms::Msrun.open("LPT_GFP_NUCLf.mzXML") do |ms| 
Ms::Msrun.open("000.mzXML") do |ms| 
  #indices = (1..1000).to_a
  #start = Time.now
  #indices.each do |n|
  #  ms.scan(n).spectrum[0]
  #end

  start = Time.now
  cnt = 0
  ms.each do |scan|
    scan.spectrum
    cnt += 1
  end

  #puts "#{(Time.now - start) / indices.size} / scan"
  #puts "#{Time.now - start} total secs for #{indices.size} scans"
  puts "#{(Time.now - start) / cnt} / scan"
  puts "#{Time.now - start} total secs for #{cnt} scans"
end
