# encoding: utf-8
module BSON
  module Ext

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
end
