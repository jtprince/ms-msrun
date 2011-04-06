require 'spec_helper'

require 'ms/msrun/index'

# those that behave_like should define:
# @id_list, @first_word, @last_word, @header_length
shared 'an Ms::Msrun::Index' do

  it 'is an array of doublets of byte and length' do
    @id_list.zip(@index) do |id_string, pair|
      string = IO.read(@file, pair.last, pair.first).strip
      string.matches id_string
      words = string.split(' ')
      words.first.is @first_word
      words.last.matches @last_word
      ok string.include?(id_string)
    end
  end
  it 'gives ids' do
    @id_list.enums @index.ids
  end
  it 'is enumerable' do
    # some nonsense showing that each_cons works (hence enumberable)
    reply = @index.each_cons(3).map {|pairs| [pairs.first, pairs.last] }
    reply.size.is( @index.length - 2 )
    reply.first.size.is 2
  end
  # minimal/frozen test
end

shared 'an Ms::Msrun::Index holding scans' do
  it 'can access by integer scan number' do
    @scan_nums.zip(@index) do |scan_num, pair|
      @index.scan(scan_num).is pair
    end
  end
end

describe "an Ms::Msrun::Index needin' a file" do
  it 'requires a file to create without subclass' do
    # Meaning, to construct an Ms::Msrun::Index that is blank, you need to
    # choose either an Mzxml or Mzml class (e.g.,  Ms::Msrun::Index::Mzml)
    lambda { x = Ms::Msrun::Index.new }.should.raise(NoMethodError)
  end
end


shared 'an Ms::Msrun::Index subclass' do
  it 'determines if a file has an index' do
    @klass.has_index?(@file).is @has_index
  end
end



