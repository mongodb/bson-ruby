# encoding: utf-8
module BSON

  # Defines behaviour around objects that can be encoded.
  #
  # @since 2.0.0
  module Encodable

    # A 4 byte placeholder that would be replaced by a length at a later point.
    #
    # @since 2.0.0
    PLACEHOLDER = 0.to_bson.freeze

    # Encodes BSON to raw bytes, for types that require the length of the
    # entire bytes to be present as the first word of the encoded string. This
    # includes Hash, CodeWithScope.
    #
    # @example Encode the BSON with placeholder bytes.
    #   hash.encode_bson_with_placeholder(encoded) do |encoded|
    #     each do |field, value|
    #       encoded << value.bson_type
    #       field.to_bson_cstring(encoded)
    #       value.to_bson(encoded)
    #     end
    #   end
    #
    # @return [ String ] The encoded string.
    #
    # @since 2.0.0
    def encode_bson_with_placeholder(encoded = ''.force_encoding(BINARY))
      pos = encoded.bytesize
      encoded << PLACEHOLDER
      yield(encoded)
      encoded << NULL_BYTE
      encoded[pos, 4] = (encoded.bytesize - pos).to_bson
      encoded
    end

    def encode_string_with_placeholder(encoded = ''.force_encoding(BINARY))
      pos = encoded.bytesize
      encoded << PLACEHOLDER
      yield(encoded)
      encoded << NULL_BYTE
      encoded[pos, 4] = (encoded.bytesize - pos - 4).to_bson
      encoded
    end

    def encode_binary_data_with_placeholder(encoded = ''.force_encoding(BINARY))
      pos = encoded.bytesize
      encoded << PLACEHOLDER
      yield(encoded)
      encoded[pos, 4] = (encoded.bytesize - pos - 4 - 1).to_bson
      encoded
    end
  end
end
