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
    def to_bson(encoded = ''.force_encoding(BINARY))
      source.to_bson_cstring(encoded)
      bson_options.to_bson_cstring(encoded)
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
      def respond_to?(method)
        compile.respond_to?(method) || super
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
      # @param [ BSON ] bson The bson representing a regular expression.
      #
      # @return [ Regexp ] The decoded regular expression.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(bson)
        pattern = bson.gets(NULL_BYTE).from_bson_string.chop!
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
