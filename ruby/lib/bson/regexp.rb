# encoding: utf-8
module BSON

  # Injects behaviour for encoding and decoding regular expression values to
  # and from raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Regexp

    # A regular expression is type 0x0B in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 11.chr.force_encoding(BINARY).freeze

    # Get the regular expression as encoded BSON.
    #
    # @example Get the regular expression as encoded BSON.
    #   %r{\d+}.to_bson
    #
    # @note From the BSON spec: The first cstring is the regex pattern,
    #   the second is the regex options string. Options are identified
    #   by characters, which must be stored in alphabetical order.
    #   Valid options are 'i' for case insensitive matching,
    #   'm' for multiline matching, 'x' for verbose mode,
    #   'l' to make \w, \W, etc. locale dependent,
    #   's' for dotall mode ('.' matches everything),
    #   and 'u' to make \w, \W, etc. match unicode.
    #
    # @return [ String ] The encoded string.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson
      source.to_bson_cstring + bson_options.to_bson_cstring
    end

    private

    def bson_options
      bson_ignorecase + bson_multiline + bson_extended
    end

    def bson_extended
      (options & ::Regexp::EXTENDED != 0) ? "x" : NO_VALUE
    end

    def bson_ignorecase
      (options & ::Regexp::IGNORECASE != 0) ? "i" : NO_VALUE
    end

    def bson_multiline
      (options & ::Regexp::MULTILINE != 0) ? "ms" : NO_VALUE
    end

    module ClassMethods
      # Deserialize the regular expression from BSON.
      #
      # @param [ BSON ] bson The bson representing a regular expression.
      #
      # @return [ Regexp ] The decoded regular expression.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(bson)
        pattern = bson.gets(NULL_BYTE).from_utf8_binary.chop!
        options = 0
        while (option = bson.readbyte) != 0
          case option
          when 105 # 'i'
            options |= ::Regexp::IGNORECASE
          when 109, 115 # 'm', 's'
            options |= ::Regexp::MULTILINE
          when 120 # 'x'
            options |= ::Regexp::EXTENDED
          end
        end

        new(pattern, options)
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, ::Regexp)
  end

  # Enrich the core Regexp class with this module.
  #
  # @since 2.0.0
  ::Regexp.send(:include, Regexp)
  ::Regexp.send(:extend, Regexp::ClassMethods)
end
