# encoding: utf-8
module BSON

  # Injects behaviour for encoding and decoding arrays to
  # and from raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Array
    include Encodable

    # An array is type 0x04 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 4.chr.force_encoding(BINARY).freeze

    # Get the array as encoded BSON.
    #
    # @example Get the array as encoded BSON.
    #   [ 1, 2, 3 ].to_bson
    #
    # @note Arrays are encoded as documents, where the index of the value in
    #   the array is the actual key.
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson
      encode_bson_with_placeholder do |encoded|
        each_with_index do |value, index|
          encoded << Element.new(index.to_s, value).to_bson
        end
      end
    end

    module ClassMethods
      # Deserialize the array from BSON.
      #
      # @param [ BSON ] bson The bson representing an array.
      #
      # @return [ Array ] The decoded array.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(bson)
        array = new
        bson.read(4) # throw away the length

        while (type = bson.readbyte.chr) != NULL_BYTE
          bson.gets(NULL_BYTE)
          array << BSON::Registry.get(type).from_bson(bson)
        end

        array
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, ::Array)
  end

  # Enrich the core Array class with this module.
  #
  # @since 2.0.0
  ::Array.send(:include, Array)
  ::Array.send(:extend, Array::ClassMethods)
end
