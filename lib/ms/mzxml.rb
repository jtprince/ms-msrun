
module Ms
  module Mzxml
    module_function
    def parent_basename_and_dir(xml_value)
      fn = xml_value.gsub(/\\/, '/')
      dn = File.dirname(fn)
      dn = nil if dn == '.' && !fn.include?('/')
      [File.basename(fn), dn]
    end
  end
end
