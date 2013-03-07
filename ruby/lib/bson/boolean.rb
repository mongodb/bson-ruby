# encoding: utf-8
module BSON

  # Represents a $maxKey type, which compares less than any other value in the
  # specification.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Boolean

    # A boolean is type 0x08 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 8.chr.force_encoding(BINARY).freeze

    # Deserialize a boolean from BSON.
    #
    # @param [ BSON ] bson The encoded boolean.
    #
    # @return [ TrueClass, FalseClass ] The decoded boolean.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(bson)
      bson.readbyte == 1
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
