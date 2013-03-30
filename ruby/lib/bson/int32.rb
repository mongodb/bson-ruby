# encoding: utf-8
module BSON

  # Represents a $maxKey type, which compares less than any other value in the
  # specification.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Int32

    # A boolean is type 0x08 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 16.chr.force_encoding(BINARY).freeze

    # Constant for the int 32 pack directive.
    #
    # @since 2.0.0
    PACK = "l".freeze

    # Deserialize an Integer from BSON.
    #
    # @param [ BSON ] bson The encoded int32.
    #
    # @return [ Integer ] The decoded Integer.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(bson)
      from_bson_int32(bson.read(4))
    end

    private

    def self.from_bson_int32(bytes)
      bytes.unpack(PACK).first
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
