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
    # entire bytes to be present as the first bit of the encoded string. This
    # includes Hash, CodeWithScope.
    #
    # @example Encode the BSON with placeholder bytes.
    #   object.encode_bson_with_placeholder do |encoded|
    #     each do |field, value|
    #       encoded << Element.new(field, value).to_bson
    #     end
    #   end
    #
    # @return [ String ] The encoded string.
    #
    # @since 2.0.0
    def encode_bson_with_placeholder
      encoded = "".force_encoding(BINARY)
      encoded << PLACEHOLDER
      yield(encoded)
      encoded << NULL_BYTE
      encoded[0, 4] = encoded.bytesize.to_bson
      encoded
    end
  end
end
