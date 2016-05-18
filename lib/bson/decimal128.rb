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

    # A Decimal128 is type 0x0D in the BSON spec.
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

    # Exponent mask.
    #
    # @since 4.1.0
    EXPONENT_MASK = (3 << 61).freeze

    # Exponent offset.
    #
    # @since 4.1.0
    EXPONENT_OFFSET = 6176.freeze

    # Minimum exponent.
    #
    # @since 4.1.0
    MIN_EXPONENT = -6176.freeze

    # Maximum exponent.
    #
    # @since 4.1.0
    MAX_EXPONENT = 6111.freeze

    # The two highest bits of the 64 high order bits.
    #
    # @since 4.1.0
    TWO_HIGHEST_BITS_SET = (3 << 61).freeze

    # Regex for getting the significands.
    #
    # @since 4.1.0
    SIGNIFICANDS_REGEX = /^(0*)(\d*)/.freeze

    # Key for this type when converted to extended json.
    #
    # @since 4.1.0
    EXTENDED_JSON_KEY = "$numberDecimal".freeze

    # The native type to which this object can be converted.
    #
    # @since 4.1.0
    NATIVE_TYPE = BigDecimal.freeze

    # Get the Decimal128 as JSON hash data.
    #
    # @example Get the Decimal128 as a JSON hash.
    #   decimal.as_json
    #
    # @return [ Hash ] The number as a JSON hash.
    #
    # @since 4.1.0
    def as_json(*args)
      { EXTENDED_JSON_KEY => to_s }
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
    # @return [ true, false ] If the objects have the same high and low bits.
    #
    # @since 4.1.0
    def ===(other)
      return @high === other.instance_variable_get(:@high) &&
        @low === other.instance_variable_get(:@low)
      super
    end

    # Create a new Decimal128 from a Ruby BigDecimal.
    #
    # @example Create a Decimal128 from a BigDecimal.
    #   Decimal128.new(big_decimal)
    #
    # @param [ BigDecimal ] big_decimal The BigDecimal to use for
    #   instantiating a Decimal128.
    #
    # @raise [ InvalidBigDecimal ] Raise error unless object is a BigDecimal.
    #
    # @since 4.1.0
    def initialize(big_decimal)
      raise InvalidBigDecimal.new unless big_decimal.is_a?(BigDecimal)
      if special_big_decimal?(big_decimal)
        set_special_bit_orders(big_decimal)
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
      num = @high << 64
      num |= @low
      num.hash
    end

    # Get a nice string for use with object inspection.
    #
    # @example Inspect the decimal128 object.
    #   decimal128.inspect
    #
    # @return [ String ] The decimal as a string.
    #
    # @since 4.1.0
    def inspect
      "BSON::Decimal128('#{to_s}')"
    end

    # Get the decimal128 as its raw BSON data.
    #
    # @example Get the raw bson bytes in a buffer.
    #   decimal.to_bson
    #
    # @return [ BSON::ByteBuffer ] The raw bytes in a buffer.
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

    # Get a BigDecimal object corresponding to this Decimal128.
    # Note that the precision of the resulting BigDecimal is not guaranteed to exactly
    # match that of the MongoDB implementation.
    #
    # @example Get the decimal as a BigDecimal.
    #   decimal.to_big_decimal
    #
    # @return [ BigDecimal ] The decimal as a BigDecimal.
    #
    # @since 4.1.0
    def to_big_decimal
      NATIVE_TYPE.new(to_s)
    end

    # Raised when trying to create a Decimal128 from a non-BigDecimal type.
    #
    # @since 4.1.0
    class InvalidBigDecimal < RuntimeError; end

    # Raised when trying to create a Decimal128 with a significand outside
    #   the valid range.
    #
    # @since 4.1.0
    class InvalidSignificand < RuntimeError

      # The custom error message for this error.
      #
      # @since 4.1.0
      MESSAGE = 'Significand contains too many digits. A maximum of 34 digits is allowed'.freeze

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
      MESSAGE = 'Invalid string format for creating a Decimal128 object.'.freeze

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

    # Raised when the exponent provided is outside the valid range.
    #
    # @since 4.1.0
    class InvalidExponent < RuntimeError

      # The custom error message for this error.
      #
      # @since 4.1.0
      MESSAGE = "Exponent out of range. It must be at least #{Decimal128::MIN_EXPONENT} and ' +
                  'no greater than #{Decimal128::MAX_EXPONENT}.".freeze

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

    def set_special_bit_orders(decimal)
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
      @high = @significand >> 64
      @low = (@high << 64) ^ @significand

      if @high >> 49 == 1
        @high = @high & 0x7fffffffffff
        @high |= EXPONENT_MASK
        @high |= (@exponent & 0x3fff) << 47
      else
        @high |= @exponent << 49
      end

      @high |= SIGN_BIT_MASK if is_negative
    end

    def valid_exponent?(exp)
      exp >= MIN_EXPONENT && exp <= MAX_EXPONENT
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

    def validate_exponent!(exponent)
      raise InvalidExponent.new unless valid_exponent?(exponent)
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
      # @param [ String ] string The string to parse.
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

    # Class for representing a Decimal128 object as a string or parsing a string into
    #   a Decimal128 object.
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

        # Regex for the fraction, including leading zeros.
        #
        # @return [ Regex ] The regex for matching the fraction,
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

        # The 0 string.
        #
        # @return [ String ] The 0 string.
        #
        # @since 4.1.0
        ZERO = '0'.freeze

        # Regex for a valid decimal128 format.
        #
        # @return [ Regex ] The regex for a valid decimal128 string.
        #
        # @since 4.1.0
        VALID_DECIMAL128_STRING_REGEX = /^(\+|\-)?(\d+|(\d*\.\d+))?((E|e)?[\-\+]?\d+)?$/.freeze

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
          exponent, significant_digits = round_exact!(exponent, significant_digits)
          exponent, significant_digits = clamp!(exponent, significant_digits)

          [ significant_digits, exponent, sign == '-' ]
        end

        def round_exact!(exponent, significant_digits)
          if exponent < Decimal128::MIN_EXPONENT
            while exponent < Decimal128::MIN_EXPONENT && significant_digits[-1] == ZERO
              exponent += 1
              significant_digits.slice!(ZERO)
            end
          end

          [exponent, significant_digits]
        end

        def clamp!(exponent, significant_digits)
          if exponent > Decimal128::MAX_EXPONENT
            while exponent > Decimal128::MAX_EXPONENT && significant_digits.length < 34
              exponent -= 1
              significant_digits << ZERO
            end
          end
          [exponent, significant_digits]
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

      # Initialize the Decimal128 string parser.
      #
      # @example Initialize the string parser.
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
        significand = high_bits & 0x1ffffffffffff
        significand = significand << 64
        significand |= low_bits
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
        high_bits & Decimal128::TWO_HIGHEST_BITS_SET == Decimal128::TWO_HIGHEST_BITS_SET
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
        @decimal.instance_variable_get(:@high)
      end

      def low_bits
        @decimal.instance_variable_get(:@low)
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 4.1.0
    Registry.register(BSON_TYPE, self)
  end
end
