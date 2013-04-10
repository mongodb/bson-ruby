# encoding: utf-8
module BSON

  # Represents a $maxKey type, which compares less than any other value in the
  # specification.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Int64

    # A boolean is type 0x08 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 18.chr.force_encoding(BINARY).freeze

    # Constant for the int 64 pack directive.
    #
    # @since 2.0.0
    PACK = "q<".freeze

    # Deserialize an Integer from BSON.
    #
    # @param [ BSON ] bson The encoded int64.
    #
    # @return [ Integer ] The decoded Integer.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(bson)
      from_bson_int64(bson.read(8))
    end

    private

    def self.from_bson_int64(bytes)
      bytes.unpack(PACK).first
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
