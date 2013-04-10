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
    BSON_ADJUST = 0.freeze # total number of doc bytes includes int32
    STRING_ADJUST = -4.freeze # total number of string bytes does not include int32

    # Encodes BSON to raw bytes, for types that require the length of the
    # entire bytes to be present as the first word of the encoded string. This
    # includes Hash, CodeWithScope.
    #
    # @example Encode the BSON with placeholder bytes.
    #   hash.encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
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
    def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BINARY))
      pos = encoded.bytesize
      encoded << PLACEHOLDER
      yield(encoded)
      encoded << NULL_BYTE
      encoded[pos, 4] = (encoded.bytesize - pos + adjust).to_bson_int32
      encoded
    end

    def encode_binary_data_with_placeholder(encoded = ''.force_encoding(BINARY))
      pos = encoded.bytesize
      encoded << PLACEHOLDER
      yield(encoded)
      encoded[pos, 4] = (encoded.bytesize - pos - 5).to_bson_int32
      encoded
    end
  end
end
