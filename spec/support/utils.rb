module Utils
  # JRuby chokes when strings like "\xfe\x00\xff", which are not valid UTF-8,
  # appear in the source. Use this method to build such strings.
  # char_array is an array of byte values to use for the string.
  module_function def make_byte_string(char_array, encoding = 'BINARY')
    char_array.map do |char|
      char.chr.force_encoding('BINARY')
    end.join.force_encoding(encoding)
  end
end
