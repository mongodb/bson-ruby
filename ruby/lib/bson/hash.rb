# encoding: utf-8
module BSON

  # Injects behaviour for encoding and decoding hashes to
  # and from raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Hash

    # An hash (embedded document) is type 0x03 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 3.chr.freeze

    # A 4 byte placeholder that would be replaced by a length at a later point.
    #
    # @since 2.0.0
    PLACEHOLDER = 0.to_bson.freeze

    # Get the hash as encoded BSON.
    #
    # @example Get the hash as encoded BSON.
    #   { field: "value" }.to_bson
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson
      with_placeholder do |encoded|
        each do |field, value|
          encoded << Element.new(field, value).to_bson
        end
      end
    end

    private

    def with_placeholder
      encoded = "".force_encoding(String::BINARY)
      encoded << PLACEHOLDER
      yield(encoded)
      encoded << NULL_BYTE
      encoded[0, 4] = encoded.bytesize.to_bson
      encoded
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, ::Hash)
  end

  # Enrich the core Hash class with this module.
  #
  # @since 2.0.0
  ::Hash.send(:include, Hash)
end
