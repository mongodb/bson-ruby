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

require 'bigdecimal'

module BSON

  # Represents a Decimal128 value.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 4.1.0
  class Decimal128
    include JSON

    # A Decimcal128 is type 0x0D in the BSON spec.
    #
    # @since 4.1.0
    BSON_TYPE = 19.chr.force_encoding(BINARY).freeze

    # Infinity mask.
    #
    # @since 4.1.0
    INFINITY_MASK = 0x7800000000000000.freeze

    # NaN mask.
    #
    # @since 4.1.0
    NAN_MASK = 0x7c00000000000000.freeze

    # Signed bit mask.
    #
    # @since 4.1.0
    SIGN_BIT_MASK = (1 << 63).freeze

    # Exponent offset.
    #
    # @since 4.1.0
    EXPONENT_OFFSET = 6176.freeze

    # Weird exponent mask (?)
    #
    # @since 4.1.0
    TWO_HIGH_BITS_SET = (3 << 61).freeze

    # Regex for getting the significands.
    #
    # @since 4.1.0
    SIGNIFICANDS_REGEX = /^(0*)(\d*)/.freeze

    # Get the Decimal128 as JSON hash data.
    #
    # @example Get the Decimal128 as a JSON hash.
    #   decimal.as_json
    #
    # @return [ Hash ] The number as a JSON hash.
    #
    # @since 4.1.0
    def as_json(*args)
      { "$numberDecimal" => to_s }
    end

    # Check equality of the decimal128 object with another object.
    #
    # @example Check if the decimal128 object is equal to the other.
    #   decimal == other
    #
    # @param [ Object ] other The object to check against.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 4.1.0
    def ==(other)
      return false unless other.is_a?(Decimal128)
      @high == other.instance_variable_get(:@high) &&
        @low == other.instance_variable_get(:@low)
    end
    alias :eql? :==

    # Check case equality on the decimal128 object.
    #
    # @example Check case equality.
    #   decimal === other
    #
    # @param [ Object ] other The object to check against.
    #
    # @return [ true, false ] If the objects are have the same high and low bits.
    #
    # @since 4.1.0
    def ===(other)
      return @high === other.instance_variable_get(:@high) &&
        @low === other.instance_variable_get(:@low)
      super
    end

    # Compare this decimal128 with another object for use in sorting.
    #
    # @example Compare the decimal128 object with the other object.
    #   object <=> other
    #
    # @param [ Object ] other The object to compare to.
    #
    # @return [ Integer ] The result of the comparison.
    #
    # @since 2.0.0
    def <=>(other)
      # @todo
    end

    # Create a new Decimal128 from a Ruby BigDecimal.
    #
    # @example Create a Decimal128 from a BigDecimal.
    #   Decimal128.new(big_decimal)
    #
    # @param [ BigDecimal ] big_decimal The BigDecimal to use for
    #   instantiating a Decimal128.
    #
    # @since 4.1.0
    def initialize(big_decimal)
      raise Invalid.new unless big_decimal.is_a?(BigDecimal)
      if special_big_decimal?(big_decimal)
        set_special_values(big_decimal)
      else
        sign, sig_digits, exponent = split_big_decimal(big_decimal)
        set_bits(sig_digits, exponent, sign == BigDecimal::SIGN_NEGATIVE_FINITE)
      end
    end

    # Get the hash value for the decimal128.
    #
    # @example Get the hash value.
    #   decimal.hash
    #
    # @return [ Integer ] The hash value.
    #
    # @since 4.1.0
    def hash
      num = @high << 63
      num |= @low
      num.hash
    end

    # Get a nice string for use with object inspection.
    #
    # @example Inspect the decimal object.
    #   decimal128.inspect
    #
    # @return [ String ] The decimal as a string.
    #
    # @since 4.1.0
    def inspect
      "BSON::Decimal128('#{to_s}')"
    end

    # Dump the raw bson when calling Marshal.dump.
    #
    # @example Dump the raw bson.
    #   Marshal.dump(decimal)
    #
    # @return [ String ] The raw bson bytes.
    #
    # @since 4.1.0
    def marshal_dump
      # @todo
    end

    # Unmarshal the data into a decimal128 object.
    #
    # @example Unmarshal the data.
    #   Marshal.load(data)
    #
    # @param [ String ] data The raw bson bytes.
    #
    # @return [ String ] The raw bson bytes.
    #
    # @since 4.1.0
    def marshal_load(data)
      # @todo
    end

    # Get the decimal128 as its raw BSON data.
    #
    # @example Get the raw bson bytes.
    #   decimal.to_bson
    #
    # @return [ ByteBuffer ] The raw bytes.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 4.1.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      buffer.put_decimal128(@low, @high)
    end

    # Get the string representation of the decimal128.
    #
    # @example Get the decimal as a string.
    #   decimal.to_s
    #
    # @return [ String ] The decimal as a string.
    #
    # @since 4.1.0
    def to_s
      @string ||= Parser.new(self).string
    end
    alias :to_str :to_s

    # Raised when trying to create a Decimal128 from an invalid type.
    #
    # @since 4.1.0
    class Invalid < RuntimeError; end

    # Raised when trying to create a Decimal128 with a significand outside
    #   the valid range.
    #
    # @since 4.1.0
    class InvalidRange < RuntimeError

      # The custom error message for this error.
      #
      # @since 4.1.0
      MESSAGE = 'Invalid significand range.'.freeze

      # Get the custom error message for the exception.
      #
      # @example Get the message.
      #   error.message
      #
      # @return [ String ] The error message.
      #
      # @since 4.1.0
      def message
        MESSAGE
      end
    end

    # Raised when trying to create a Decimal128 from a string with
    #   an invalid format.
    #
    # @since 4.1.0
    class InvalidString < RuntimeError

      # The custom error message for this error.
      #
      # @since 4.1.0
      MESSAGE = 'Invalid string format for Decimal128.'.freeze

      # Get the custom error message for the exception.
      #
      # @example Get the message.
      #   error.message
      #
      # @return [ String ] The error message.
      #
      # @since 4.1.0
      def message
        MESSAGE
      end
    end

    private

    def split_big_decimal(value)
      simple_sign, digits, base, exp = value.split
      exponent = exp - digits.length
      [ value.sign, digits, exponent ]
    end

    def special_big_decimal?(decimal)
      decimal.infinite? || decimal.nan?
    end

    def set_special_values(decimal)
      @low = 0
      case decimal.sign
        when BigDecimal::SIGN_POSITIVE_INFINITE
          @high = INFINITY_MASK
        when BigDecimal::SIGN_NEGATIVE_INFINITE
          @high = INFINITY_MASK | SIGN_BIT_MASK
        when BigDecimal::SIGN_NaN
          @high = NAN_MASK
      end
    end

    def set_bits(significand_str, exponent, is_negative = false)
      validate_range!(significand_str)
      set_exponent!(exponent)
      set_high_low_bits(significand_str, is_negative)
    end

    def set_high_low_bits(significand_str, is_negative = false)
      @significand = significand_str.to_i.abs
      @low = get_low_bits(@significand)
      @high = get_high_bits(@significand)

      if @high >> 49 == 1
        @high = @high & 0x7fffffffffff
        @high |= 0x3 << 61
        @high |= @exponent & 0x3fff << 47
      else
        @high |= @exponent << 49
      end

      if is_negative
        @high |= SIGN_BIT_MASK
      end
    end

    def set_exponent!(exponent)
      validate_exponent!(exponent)
      @exponent = exponent + EXPONENT_OFFSET
    end

    def validate_range!(significand_str)
      unless SIGNIFICANDS_REGEX.match(significand_str).to_a[2].length <= 34
        raise InvalidRange.new
      end
    end

    def validate_exponent!(exp)
      # @todo
    end

    def get_low_bits(significand)
      low_bits = 0
      0.upto(63) do |i|
        if significand[i] == 1
          low_bits |= 1 << i
        end
      end
      low_bits
    end

    def get_high_bits(significand)
      high_bits = 0
      # todo check upto
      64.upto(127) do |i|
        if significand[i] == 1
          high_bits |= 1 << (i - 64)
        end
      end
      high_bits
    end

    class << self

      # Deserialize the Decimal128 from raw BSON bytes.
      #
      # @example Get the decimal128 from BSON.
      #   Decimal128.from_bson(bson)
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @return [ BSON::Decimal128 ] The decimal object.
      #
      # @since 4.1.0
      def from_bson(buffer)
        decimal = allocate
        bytes = buffer.get_decimal128_bytes
        low, high = bytes.unpack('Q*')
        decimal.instance_variable_set(:@low, low)
        decimal.instance_variable_set(:@high, high)
        decimal
      end

      # Create a new decimal128 from a string.
      #
      # @example Create a decimal128 from the string.
      #   BSON::Decimal128.from_string("1.05E+3")
      #
      # @param [ String ] string The string to create the decimal from.
      #
      # @raise [ BSON::Decimal128::InvalidString ] If the provided string is invalid.
      #
      # @return [ BSON::Decimal128 ] The new decimal128.
      #
      # @since 4.1.0
      def from_string(string)
        if decimal = Parser.parse_special_type(string)
          return decimal
        end
        decimal = allocate
        decimal.send(:set_bits, *Parser.parse_string(string))
        decimal
      end
    end

    # Class for parsing a decimal into and from a string.
    #
    # @since 4.1.0
    class Parser

      class << self

        # Regex matching a scientific exponent.
        #
        # @return [ Regex ] A regex matching E, e, E+, e+.
        #
        # @since 4.1.0
        SCIENTIFIC_EXPONENT_REGEX = /(E|e)\+?/.freeze

        # Regex matching a string representing positive or negative Infinity.
        #
        # @return [ Regex ] A regex matching a positive or negative Infinity string.
        #
        # @since 4.1.0
        INFINITY_REGEX = /^(\+|\-)?Inf(inity)?$/i.freeze

        # Regex matching a string representing NaN.
        #
        # @return [ Regex ] A regex matching a NaN string.
        #
        # @since 4.1.0
        NAN_REGEX = /^NaN$/i.freeze

        # Regex for a post-decimal significand with leading zeros.
        #
        # @return [ Regex ] The regex for matching a post-decimal significand
        #   including leading zeros.
        #
        # @since 4.1.0
        SIGNIFICAND_WITH_LEADING_ZEROS = /(0*)(\d+)/.freeze

        # The decimal point string.
        #
        # @return [ String ] A decimal point.
        #
        # @since 4.1.0
        DECIMAL_POINT = '.'.freeze

        # Regex for a valid decimal128 format.
        #
        # @return [ Regex ] The regex for a valid decimal128 string.
        #
        # @since 4.1.0
        VALID_DECIMAL128_STRING_REGEX = /^(\+|\-)?\d+(\.\d+)?((E|e)?[\-\+]?\d+)?$/.freeze

        # Regex for separating a negative sign from the significands.
        #
        # @return [ Regex ] The regex for separating a sign from significands.
        #
        # @since 4.1.0
        SIGN_DIGITS_SEPARATOR = /^(\-)?(\S+)/.freeze

        # Extract the decimal128 components from a string.
        #
        # @example Get the significand, exponent and sign from a string.
        #  Parser.parse_string('1.23')
        #
        # @param [ String ] string The string to parse.
        #
        # @return [ Array<Object> ] The extracted significand, exponent
        #   and whether the decimal128 is negative.
        #
        # @since 4.1.0
        def parse_string(string)
          validate!(string)
          original, sign, digits_str = SIGN_DIGITS_SEPARATOR.match(string).to_a

          digits, e, scientific_exp = digits_str.partition(SCIENTIFIC_EXPONENT_REGEX)
          before_decimal, decimal, after_decimal = digits.partition(DECIMAL_POINT)

          if before_decimal.to_i >= 0
            significant_digits = before_decimal << after_decimal
          else
            significant_digits = SIGNIFICAND_WITH_LEADING_ZEROS.match(after_decimal).to_a[2]
          end
          exponent = -(after_decimal.length)
          exponent = exponent + scientific_exp.to_i

          [ significant_digits, exponent, sign == '-' ]
        end

        # Parse a string representing positive or negative Infinity or NaN.
        #
        # @example Parse the string representing a special type.
        #  Parser.parse_string('Nan')
        #
        # @param [ String ] string The string to parse.
        #
        # @return [ BSON::Decimal128 ] The corresponding Decimal128 object.
        #
        # @since 4.1.0
        def parse_special_type(string)
          if string =~ NAN_REGEX
            BSON::Decimal128.new(BigDecimal(NAN_STRING))
          elsif match = INFINITY_REGEX.match(string)
            BSON::Decimal128.new(BigDecimal("#{match[1]}#{INFINITY_STRING}"))
          end
        end

        private

        def validate!(string)
          raise BSON::Decimal128::InvalidString.new unless string =~ VALID_DECIMAL128_STRING_REGEX
        end
      end

      # String representing a NaN value.
      #
      # @return [ String ] The string representing NaN.
      #
      # @since 4.1.0
      NAN_STRING = 'NaN'.freeze

      # String representing an Infinity value.
      #
      # @return [ String ] The string representing Infinity.
      #
      # @since 4.1.0
      INFINITY_STRING = 'Infinity'.freeze

      # Initialize the Decimal128 parser.
      #
      # @example Initialize the parser.
      #  Parser.new(decimal)
      #
      # @param [ BSON::Decimal128 ] The decimal128 to be parsed.
      #
      # @since 4.1.0
      def initialize(decimal)
        @decimal = decimal
      end

      # Get the string representing the Decimal128 object.
      #
      # @example Get a string representing the Decimal128 object.
      #  parser.string
      #
      # @return [ String ] The string representing the decimal128.
      #
      # @since 4.1.0
      def string
        return NAN_STRING if nan?
        string = infinity? ? INFINITY_STRING : parse
        negative? ? '-' << string : string
      end

      private

      def parse
        high_bits = @decimal.instance_variable_get(:@high)
        low_bits = @decimal.instance_variable_get(:@low)
        significand = 0

        0.upto(112) do |i|
          if i < 64
            if low_bits[i] == 1
              significand |= 1 << i
            end
          else
            if high_bits[i - 64] == 1
              significand |= 1 << i
            end
          end
        end
        get_string(significand)
      end

      def get_string(significand)
        sig_string = two_highest_bits_set? ? '0' : significand.to_s
        if use_scientific_notation?(sig_string)
          sign = exponent < 0 ? '' : '+'
          beginning = sig_string.length > 1 ?  sig_string[0] << '.' : sig_string
          sig_string = beginning << sig_string[1..-1] << "E#{sign}" << @scientific_exponent.to_s
        elsif exponent < 0
          pad = (exponent + sig_string.length).abs
          if sig_string.length > exponent.abs
            sig_string = sig_string[0..(sig_string.length - exponent.abs-1)] << '.' << sig_string[(sig_string.length - exponent.abs)..-1]
          else
            sig_string = '0.' << '0' * pad << sig_string
          end
        end
        sig_string
      end

      def use_scientific_notation?(significand_string)
        @scientific_exponent = (significand_string.length - 1) + exponent
        exponent > 0 || @scientific_exponent < -6
      end

      def exponent
        @exponent ||= two_highest_bits_set? ?
                        ((high_bits & 0x1fffe00000000000) >> 47) - Decimal128::EXPONENT_OFFSET :
                        ((high_bits & 0x7fff800000000000) >> 49) - Decimal128::EXPONENT_OFFSET
      end

      def two_highest_bits_set?
        high_bits & Decimal128::TWO_HIGH_BITS_SET == Decimal128::TWO_HIGH_BITS_SET
      end

      def nan?
        high_bits & Decimal128::NAN_MASK == Decimal128::NAN_MASK
      end

      def negative?
        high_bits & Decimal128::SIGN_BIT_MASK == Decimal128::SIGN_BIT_MASK
      end

      def infinity?
        high_bits & Decimal128::INFINITY_MASK == Decimal128::INFINITY_MASK
      end

      def high_bits
        @high_bits ||= @decimal.instance_variable_get(:@high)
      end

      def low_bits
        @low_bits ||= @decimal.instance_variable_get(:@low)
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 4.1.0
    Registry.register(BSON_TYPE, self)
  end
end
