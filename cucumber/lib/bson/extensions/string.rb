module BSON
  module Extensions
    module String
      def __bson_export__(io, key)
        io << Types::STRING
        io << key.to_bson_cstring

        data = to_utf8_binary

        io << [ data.bytesize + 1 ].pack(INT32_PACK)
        io << data
        io << NULL_BYTE
      end

      def to_bson_string
        cstring = to_bson_cstring
        [ cstring.bytesize ].pack(INT32_PACK) + cstring
      end

      def to_bson_cstring
        if include? NULL_BYTE
          raise EncodingError, "#{inspect} cannot be converted to a BSON " \
            "cstring because it contains a null byte"
        end

        to_utf8_binary << NULL_BYTE
      end

      def to_utf8_binary
        encode(UTF8_ENCODING).force_encoding(BINARY_ENCODING)
      rescue EncodingError
        data = dup.force_encoding(UTF8_ENCODING)
        raise unless data.valid_encoding?
        data.force_encoding(BINARY_ENCODING)
      end

      def from_utf8_binary
        force_encoding(UTF8_ENCODING).encode!
      end
    end
  end
end