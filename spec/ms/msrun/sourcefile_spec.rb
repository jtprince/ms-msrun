require 'spec_helper'

require 'ms/msrun/sourcefile'

shared 'a sourcefile' do
  it 'behaves as expected with attributes' do
    @sourcefile.name.is @name
    @sourcefile.location.is @location
    @sourcefile.id.is @id
  end
  it 'extracts basename from name' do
    @sourcefile.basename.is @basename
  end
  it 'extracts basename_noext from name' do
    @sourcefile.basename_noext.is @basename_noext
  end
  it 'returns the whether the name is a uri' do
    @sourcefile.name_is_uri?.is @name_is_uri
  end
  it 'returns the protocol and host' do
    @sourcefile.host.is @host
    @sourcefile.protocol.is @protocol
  end
  it 'returns the full_uri' do
    @sourcefile.full_uri.is @full_uri
  end
  it 'gives the dirname' do
    @sourcefile.dirname.is @dirname
  end
end

describe 'a sourcefile where the name is a complete URI' do
  before do
    # this is a sourcefile name derived from OpenMS
    # and is one way to express the name/location of the file
    # (i.e., no location, everything in the name)
    @id = "filler"
    @name = "file://E130JP3/c/Inetpub/wwwroot/ISB/data/Hek_cells_100904050914.RAW"
    @location = nil
    @sourcefile = Ms::Msrun::Sourcefile.new(@id, @name, @location)

    @protocol = 'file'
    @name_is_uri = true
    @full_uri = @name
    @basename = "Hek_cells_100904050914.RAW"
    @basename_noext = "Hek_cells_100904050914"
    @host = "E130JP3"
    @dirname = "/c/Inetpub/wwwroot/ISB/data"
    @host_and_dirname = [@host, @dirname]
  end
  behaves_like "a sourcefile"
end
  
describe 'a sourcefile where the name and location specify local paths' do
  before do
    # this is a sourcefile name derived from msconvert (pwiz)
    @id = "RAW1"
    @name = "j24.raw"
    @location = "file://C:/Documents and Settings/Sequest/Desktop/pwiz/.."
    @sourcefile = Ms::Msrun::Sourcefile.new(@id, @name, @location)

    @protocol = 'file'
    @name_is_uri = false
    @full_uri = "file://C:/Documents and Settings/Sequest/Desktop/pwiz/../#{@basename}"
    @basename = "j24.raw"
    @basename_noext = "j24"
    @host = nil
    @dirname = "C:/Documents and Settings/Sequest/Desktop/pwiz/.."
    @host_and_dirname = [@host, @dirname]
  end
  behaves_like "a sourcefile"
end

describe 'creates a valid Sourcefile object from a local fullpath' do
  it 'works' do
    myid = "hello1"
    sf = Ms::Msrun::Sourcefile.from_local_fullpath(myid, "/full/path/to/my/file.raw")
    sf.name.is 'file.raw'
    sf.location.is 'file:///full/path/to/my'
  end
end
