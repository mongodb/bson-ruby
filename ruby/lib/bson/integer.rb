# encoding: utf-8
module BSON

  # Injects behaviour for encoding and decoding integer values to and from
  # raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Integer

    # A 32bit integer is type 0x10 in the BSON spec.
    #
    # @since 2.0.0
    INT32_TYPE = 16.chr.force_encoding(BINARY).freeze

    # A 64bit integer is type 0x12 in the BSON spec.
    #
    # @since 2.0.0
    INT64_TYPE = 18.chr.force_encoding(BINARY).freeze

    # The maximum 32 bit integer value.
    #
    # @since 2.0.0
    MAX_32BIT = (1 << 31) - 1

    # The maximum 64 bit integer value.
    #
    # @since 2.0.0
    MAX_64BIT = (1 << 63) - 1

    # The minimum 32 bit integer value.
    #
    # @since 2.0.0
    MIN_32BIT = -(1 << 31)

    # The minimum 64 bit integer value.
    #
    # @since 2.0.0
    MIN_64BIT = -(1 << 63)

    # Is this integer a valid BSON 32 bit value?
    #
    # @example Is the integer a valid 32 bit value?
    #   1024.bson_int32?
    #
    # @return [ true, false ] If the integer is 32 bit.
    #
    # @since 2.0.0
    def bson_int32?
      (MIN_32BIT <= self) && (self <= MAX_32BIT)
    end

    # Is this integer a valid BSON 64 bit value?
    #
    # @example Is the integer a valid 64 bit value?
    #   1024.bson_int64?
    #
    # @return [ true, false ] If the integer is 64 bit.
    #
    # @since 2.0.0
    def bson_int64?
      (MIN_64BIT <= self) && (self <= MAX_64BIT)
    end

    # Get the BSON type for this integer. Will depend on whether the integer
    # is 32 bit or 64 bit.
    #
    # @example Get the BSON type for the integer.
    #   1024.bson_type
    #
    # @return [ String ] The single byte BSON type.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def bson_type
      bson_int32? ? INT32_TYPE : (bson_int64? ? INT64_TYPE : out_of_range!)
    end

    # Get the integer as encoded BSON.
    #
    # @example Get the integer as encoded BSON.
    #   1024.to_bson
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson
      [ self ].pack(bson_pack_directive)
    end

    private

    def bson_pack_directive
      bson_int32? ? INT32_PACK : (bson_int64? ? INT64_PACK : out_of_range!)
    end

    def out_of_range!
      raise Int64::OutOfRange.new("#{self} is not a valid 8 byte integer value.")
    end
  end

  # Enrich the core Integer class with this module.
  #
  # @since 2.0.0
  ::Integer.send(:include, Integer)
end
