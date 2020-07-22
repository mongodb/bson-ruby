# Copyright (C) 2009-2020 MongoDB Inc.
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
    #
    # @deprecated Will be removed in 5.0
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
    # @param [ BSON::ByteBuffer ] buffer The byte buffer to append to.
    # @param [ true, false ] validating_keys
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      buffer.put_cstring(source)
      buffer.put_cstring(bson_options)
    end

    private

    def bson_options
      # Ruby's Regexp always has BSON's equivalent of 'm' on, so always add it
      bson_ignorecase + MULTILINE_VALUE + bson_dotall + bson_extended
    end

    def bson_extended
      (options & ::Regexp::EXTENDED != 0) ? EXTENDED_VALUE : NO_VALUE
    end

    def bson_ignorecase
      (options & ::Regexp::IGNORECASE != 0) ? IGNORECASE_VALUE : NO_VALUE
    end

    def bson_dotall
      # Ruby Regexp's MULTILINE is equivalent to BSON's dotall value
      (options & ::Regexp::MULTILINE != 0) ? NEWLINE_VALUE : NO_VALUE
    end

    # Represents the raw values for the regular expression.
    #
    # @see https://jira.mongodb.org/browse/RUBY-698
    #
    # @since 3.0.0
    class Raw
      include JSON

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
        @compiled ||= ::Regexp.new(pattern, options_to_i)
      end

      # Initialize the new raw regular expression.
      #
      # @example Initialize the raw regexp.
      #   Raw.new(pattern, options)
      #
      # @param [ String ] pattern The regular expression pattern.
      # @param [ nil | String | Integer ] options The options.
      #
      # @note The ability to specify options as an Integer is deprecated.
      #  Please specify options as a String. The ability to pass options as
      #  as Integer will be removed in version 5.0.0.
      #
      # @since 3.0.0
      def initialize(pattern, options = '')
        # Funky options handling for backwards compatibility.
        # The options as given are written to @options and are exposed via the
        # options attribute.
        # String options are exposed as options_str.
        # Integer options are exposed as options_int.
        # If there are no options, options_str and options_int will be nil
        # but options may be an empty string or 0.
        unless options.nil? || String === options || Integer === options
          raise ArgumentError, "Options must be a String or an Integer: #{options.inspect}"
        end
        @options = options || ''
        if options == '' || options == 0
          @options_i = @options_s = nil
        elsif String === options
          @options_i = options_to_i
          @options_s = options
        else
          @options_i = options
          @options_s = options_to_s
        end

        # MQL $regex operator can take separate $options as a peer hash key.
        # To support this we allow our Regexp::Raw instances to be constructed
        # from strings & options as well as from regexps & options.
        case pattern
        when self.class
          if pattern.options_i && options_i
            raise ArgumentError, "BSON::Regexp::Raw argument to constructor may not contain options if options are also provided separately"
          end
          if options_i.nil?
            @options_i = pattern.options_i
            @options_s = pattern.options_s
            @options = pattern.options_s
          end
          pattern = pattern.pattern
        when ::Regexp
          if pattern.options > 0 && options_i
            raise ArgumentError, "Regexp argument to constructor may not contain options if options are also provided separately"
          end
          if options_i.nil?
            @options_i = pattern.options
            @options = pattern.options
            @options_s = options_to_s
            @options = pattern.options_s
          end
          pattern = pattern.source
        when String
          # Nothing
        else
          raise ArgumentError, "Pattern must be a String, a Regexp or a BSON::Regexp::Raw instance: #{pattern.inspect}"
        end
        @pattern = pattern
      end

      # Allow automatic delegation of methods to the Regexp object
      # returned by +compile+.
      #
      # @param [ String] method The name of a method.
      #
      # @since 3.1.0
      def respond_to?(method, include_private = false)
        if defined?(@pattern)
          compile.respond_to?(method, include_private) || super
        else
          # YAML calls #respond_to? during deserialization, before the object
          # is initialized.
          super
        end
      end

      # Encode the Raw Regexp object to BSON.
      #
      # @example Get the raw regular expression as encoded BSON.
      #   raw_regexp.to_bson
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
      # @param [ BSON::ByteBuffer ] buffer The byte buffer to append to.
      # @param [ true, false ] validating_keys
      #
      # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 4.2.0
      def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
        return compile.to_bson(buffer, validating_keys) if options.is_a?(Integer)
        buffer.put_cstring(source)
        buffer.put_cstring(options.chars.sort.join)
      end

      # Get the raw BSON regexp as JSON hash data.
      #
      # @example Get the raw regexp as a JSON hash.
      #   raw_regexp.as_json
      #
      # @return [ Hash ] The raw regexp as a JSON hash.
      #
      # @since 4.2.0
      def as_json(*args)
        as_extended_json(mode: :legacy)
      end

      # Converts this object to a representation directly serializable to
      # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
      #
      # @option opts [ nil | :relaxed | :legacy ] :mode Serialization mode
      #   (default is canonical extended JSON)
      #
      # @return [ Hash ] The extended json representation.
      def as_extended_json(**opts)
        if opts[:mode] == :legacy
          { "$regex" => source, "$options" => options }
        else
          {"$regularExpression" => {'pattern' => source, "options" => options}}
        end
      end

      # Check equality of the raw bson regexp against another.
      #
      # @example Check if the raw bson regexp is equal to the other.
      #   raw_regexp == other
      #
      # @param [ Object ] other The object to check against.
      #
      # @return [ true, false ] If the objects are equal.
      #
      # @since 4.2.0
      def ==(other)
        return false unless other.is_a?(::Regexp::Raw)
        pattern == other.pattern &&
          options == other.options
      end
      alias :eql? :==

      private

      def method_missing(method, *arguments)
        return super unless respond_to?(method)
        compile.send(method, *arguments)
      end

      def options_to_i
        return 0 unless options
        return options if options.is_a?(Integer)
        # TODO warn or fail on unhandled options
        opts = 0
        opts |= ::Regexp::IGNORECASE if options.include?(IGNORECASE_VALUE)
        opts |= ::Regexp::MULTILINE if options.include?(NEWLINE_VALUE)
        opts |= ::Regexp::EXTENDED if options.include?(EXTENDED_VALUE)
        opts
      end

      def options_to_s
        return options if options.is_a?(String)
        # TODO warn or fail on unhandled options
        opts = ''
        opts << ::Regexp::IGNORECASE_VALUE if options & ::Regexp::IGNORECASE > 0
        opts << ::Regexp::NEWLINE_VALUE if options & ::Regexp::MULTILINE > 0
        opts << ::Regexp::EXTENDED_VALUE if options & ::Regexp::EXTENDED > 0
        opts
      end
    end

    module ClassMethods

      # Deserialize the regular expression from BSON.
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @option opts [ nil | :bson ] :mode Decoding mode to use.
      #
      # @return [ Regexp ] The decoded regular expression.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(buffer, **opts)
        pattern = buffer.get_cstring
        options = buffer.get_cstring
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
