
#require 'axml'


correct = '<scan num="12">
  <peaks>ABCD</peaks>
</scan>
'


short = '<scan num="12">
  <peaks>ABCD</peaks>
'

long = '<scan num="12">
  <peaks>ABCD</peaks>
</scan>
</scan>
'

require 'xml/libxml'

XML::Error.set_handler do |error|
  puts "GOTCAH!"
  #puts error.to_s
end

[correct, short, long].each do |str|
  reader = XML::Reader.string str
  x = reader.read
  p x
end


=begin

x = AXML.parse(correct)
puts x.to_s
begin
y = AXML.parse(short)
rescue
  puts "RESCUED"
puts y.to_s
end
#x = AXML.parse(long)
#puts x.to_s
=end
