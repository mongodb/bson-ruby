# encoding: utf-8
module BSON

  # Represents a $maxKey type, which compares less than any other value in the
  # specification.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class MaxKey

    # A $maxKey is type 0x7F in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 127.chr.freeze

    # Determine if the max key is equal to another object.
    #
    # @example Check max key equality.
    #   BSON::MaxKey.new == object
    #
    # @param [ Object ] other The object to check against.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 2.0.0
    def ==(other)
      self.class == other.class
    end

    # Encode the max key - has no value since it only needs the type and field
    # name when being encoded.
    #
    # @example Encode the max key.
    #   max_key.to_bson
    #
    # @return [ String ] An empty string.
    #
    # @since 2.0.0
    def to_bson
      NO_VALUE
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
