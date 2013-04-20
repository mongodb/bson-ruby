# encoding: utf-8
module BSON

  # Injects behaviour for encoding and decoding time values to
  # and from raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Time

    # A time is type 0x09 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 9.chr.force_encoding(BINARY).freeze

    # Get the time as encoded BSON.
    #
    # @example Get the time as encoded BSON.
    #   Time.new(2012, 1, 1, 0, 0, 0).to_bson
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(encoded = ''.force_encoding(BINARY))
      encoded << [ (to_f * 1000.0).to_i ].pack(Int64::PACK)
    end

    module ClassMethods

      # Deserialize UTC datetime from BSON.
      #
      # @param [ BSON ] bson The bson representing UTC datetime.
      #
      # @return [ Time ] The decoded UTC datetime.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(bson)
        seconds, fragment = Int64.from_bson(bson).divmod(1000)
        at(seconds, fragment * 1000).utc
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, ::Time)
  end

  # Enrich the core Time class with this module.
  #
  # @since 2.0.0
  ::Time.send(:include, Time)
  ::Time.send(:extend, Time::ClassMethods)
end
