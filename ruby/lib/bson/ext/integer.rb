# encoding: utf-8
module BSON
  module Ext

    # Injects behaviour for encoding and decoding integer values to and from
    # raw bytes as specified by the BSON spec.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    module Integer

      # Constant for the int 32 pack directive.
      #
      # @since 2.0.0
      INT32_PACK = "l".freeze

      # A 32bit integer is type 0x10 in the BSON spec.
      #
      # @since 2.0.0
      INT32_TYPE = 16.chr.freeze

      def bson_type
        INT32_TYPE
      end

      def to_bson
        [ self ].pack(INT32_PACK)
      end
    end

    # Enrich the core Integer class with this module.
    #
    # @since 2.0.0
    ::Integer.send(:include, Integer)
  end
end
