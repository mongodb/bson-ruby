module BSON
  module Extensions
    module Regexp
      def __bson_export__(io, key)
        io << Types::REGEX
        io << key.to_bson_cstring
        io << source.to_bson_cstring

        io << 'i'  if (options & ::Regexp::IGNORECASE) != 0
        io << 'ms' if (options & ::Regexp::MULTILINE) != 0
        io << 'x'  if (options & ::Regexp::EXTENDED) != 0
        io << NULL_BYTE
      end
    end
  end
end