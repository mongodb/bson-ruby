# encoding: utf-8
module BSON

  # Represents a $minKey type, which compares less than any other value in the
  # specification.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class MinKey
    include Comparable

    # A $minKey is type 0xFF in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 255.chr.force_encoding(BINARY).freeze

    # Constant for always evaluating lesser in a comparison.
    #
    # @since 2.0.0
    LESSER = -1.freeze

    # Determine if the min key is equal to another object.
    #
    # @example Check min key equality.
    #   BSON::MinKey.new == object
    #
    # @param [ Object ] other The object to check against.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 2.0.0
    def ==(other)
      self.class == other.class
    end

    # When comparing a min key with any other object, the min key will always
    # be lesser.
    #
    # @example Compare with another object.
    #   min_key <=> 1000
    #
    # @param [ Object ] The object to compare against.
    #
    # @return [ Integer ] Always -1.
    #
    # @since 2.0.0
    def <=>(other)
      LESSER
    end

    # Encode the min key - has no value since it only needs the type and field
    # name when being encoded.
    #
    # @example Encode the min key value.
    #   min_key.to_bson
    #
    # @return [ String ] An empty string.
    #
    # @since 2.0.0
    def to_bson
      NO_VALUE
    end

    # Deserialize MinKey from BSON.
    #
    # @param [ BSON ] bson The encoded MinKey.
    #
    # @return [ MinKey ] The decoded MinKey.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(bson)
      self
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
