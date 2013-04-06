# encoding: utf-8
module BSON

  # Injects behaviour for encoding and decoding string values to and from
  # raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module String
    include Encodable

    # A string is type 0x02 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 2.chr.force_encoding(BINARY).freeze

    # Get the string as encoded BSON.
    #
    # @example Get the string as encoded BSON.
    #   "test".to_bson
    #
    # @raise [ EncodingError ] If the string is not UTF-8.
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(encoded = ''.force_encoding(BINARY))
      encode_string_with_placeholder(encoded) do |encoded|
        to_bson_string(encoded)
      end
    end

    # Get the string as an encoded C string.
    #
    # @example Get the string as an encoded C string.
    #   "test".to_bson_cstring
    #
    # @raise [ EncodingError ] If the string is not UTF-8.
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson_cstring
      check_for_illegal_characters!
      to_bson_string + NULL_BYTE
    end

    # Convert the string to a UTF-8 string then force to binary. This is so
    # we get errors for strings that are not UTF-8 encoded.
    #
    # @example Convert to valid BSON string.
    #   "Straße".to_bson_string
    #
    # @raise [ EncodingError ] If the string is not UTF-8.
    #
    # @return [ String ] The binary string.
    #
    # @since 2.0.0
    def to_bson_string(encoded = ''.force_encoding(BINARY))
      begin
        encoded << encode(UTF8).force_encoding(BINARY)
      rescue EncodingError
        data = dup.force_encoding(UTF8)
        raise unless data.valid_encoding?
        encoded << data.force_encoding(BINARY)
      end
    end

    # Convert the string to a hexidecimal representation.
    #
    # @example Convert the string to hex.
    #   "\x01".to_hex_string
    #
    # @return [ String ] The string as hex.
    #
    # @since 2.0.0
    def to_hex_string
      unpack("H*")[0]
    end

    # Take the binary string and return a UTF-8 encoded string.
    #
    # @example Convert from a BSON string.
    #   "\x00".from_bson_string
    #
    # @raise [ EncodingError ] If the string is not UTF-8.
    #
    # @return [ String ] The UTF-8 string.
    #
    # @since 2.0.0
    def from_bson_string
      force_encoding(UTF8).encode!
    end

    module ClassMethods

      # Deserialize a string from BSON.
      #
      # @param [ BSON ] bson The bson representing a string.
      #
      # @return [ Regexp ] The decoded string.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(bson)
        bson.read(*bson.read(4).unpack(Int32::PACK)).from_bson_string.chop!
      end
    end

    private

    def check_for_illegal_characters!
      if include?(NULL_BYTE)
        raise EncodingError.new("Illegal C-String '#{self}' contains a null byte.")
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, ::String)
  end

  # Enrich the core String class with this module.
  #
  # @since 2.0.0
  ::String.send(:include, String)
  ::String.send(:extend, String::ClassMethods)
end
