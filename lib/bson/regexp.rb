# Copyright (C) 2009-2015 MongoDB Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module BSON

  # Injects behaviour for encoding and decoding regular expression values to
  # and from raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Regexp
    include JSON

    # A regular expression is type 0x0B in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 11.chr.force_encoding(BINARY).freeze

    # Extended value constant.
    #
    # @since 3.2.6
    EXTENDED_VALUE = 'x'.freeze

    # Ignore case constant.
    #
    # @since 3.2.6
    IGNORECASE_VALUE = 'i'.freeze

    # Multiline constant.
    #
    # @since 3.2.6
    MULTILINE_VALUE = 'm'.freeze

    # Newline constant.
    #
    # @since 3.2.6
    NEWLINE_VALUE = 's'.freeze

    # Ruby multiline constant.
    #
    # @since 3.2.6
    RUBY_MULTILINE_VALUE = 'ms'.freeze

    # Get the regexp as JSON hash data.
    #
    # @example Get the regexp as a JSON hash.
    #   regexp.as_json
    #
    # @return [ Hash ] The regexp as a JSON hash.
    #
    # @since 2.0.0
    def as_json(*args)
      { "$regex" => source, "$options" => bson_options }
    end

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
    def to_bson(buffer = ByteBuffer.new)
      buffer.put_cstring(source)
      buffer.put_cstring(bson_options)
    end

    private

    def bson_options
      bson_ignorecase + bson_multiline + bson_extended
    end

    def bson_extended
      (options & ::Regexp::EXTENDED != 0) ? EXTENDED_VALUE : NO_VALUE
    end

    def bson_ignorecase
      (options & ::Regexp::IGNORECASE != 0) ? IGNORECASE_VALUE : NO_VALUE
    end

    def bson_multiline
      (options & ::Regexp::MULTILINE != 0) ? RUBY_MULTILINE_VALUE : NO_VALUE
    end

    # Represents the raw values for the regular expression.
    #
    # @see https://jira.mongodb.org/browse/RUBY-698
    #
    # @since 3.0.0
    class Raw

      # @return [ String ] pattern The regex pattern.
      attr_reader :pattern

      # @return [ Integer ] options The options.
      attr_reader :options

      # Compile the Regular expression into the native type.
      #
      # @example Compile the regular expression.
      #   raw.compile
      #
      # @return [ ::Regexp ] The compiled regular expression.
      #
      # @since 3.0.0
      def compile
        @compiled ||= ::Regexp.new(pattern, options)
      end

      # Initialize the new raw regular expression.
      #
      # @example Initialize the raw regexp.
      #   Raw.new(pattern, options)
      #
      # @param [ String ] pattern The regular expression pattern.
      # @param [ Integer ] options The options.
      #
      # @since 3.0.0
      def initialize(pattern, options)
        @pattern = pattern
        @options = options
      end

      # Allow automatic delegation of methods to the Regexp object
      # returned by +compile+.
      #
      # @param [ String] method The name of a method.
      #
      # @since 3.1.0
      def respond_to?(method, include_private = false)
        compile.respond_to?(method, include_private = false) || super
      end

      private

      def method_missing(method, *arguments)
        return super unless respond_to?(method)
        compile.send(method, *arguments)
      end
    end

    module ClassMethods

      # Deserialize the regular expression from BSON.
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @return [ Regexp ] The decoded regular expression.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(buffer)
        pattern = buffer.get_cstring
        options = 0
        while (option = buffer.get_byte) != NULL_BYTE
          case option
          when IGNORECASE_VALUE
            options |= ::Regexp::IGNORECASE
          when MULTILINE_VALUE, NEWLINE_VALUE
            options |= ::Regexp::MULTILINE
          when EXTENDED_VALUE
            options |= ::Regexp::EXTENDED
          end
        end
        Raw.new(pattern, options)
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
