# frozen_string_literal: true
# Copyright (C) 2016-2020 MongoDB Inc.
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
  class Decimal128

    # Helper module for parsing String, Integer, Float, BigDecimal, and Decimal128
    # objects into other objects.
    #
    # @api private
    #
    # @since 4.2.0
    module Builder

      # Infinity mask.
      #
      # @since 4.2.0
      INFINITY_MASK = 0x7800000000000000

      # NaN mask.
      #
      # @since 4.2.0
      NAN_MASK = 0x7c00000000000000

      # SNaN mask.
      #
      # @since 4.2.0
      SNAN_MASK = (1 << 57)

      # Signed bit mask.
      #
      # @since 4.2.0
      SIGN_BIT_MASK = (1 << 63)

      # The two highest bits of the 64 high order bits.
      #
      # @since 4.2.0
      TWO_HIGHEST_BITS_SET = (3 << 61)

      extend self

      # Convert parts representing a Decimal128 into the corresponding bits.
      #
      # @param [ Integer ] significand The significand.
      # @param [ Integer ] exponent The exponent.
      # @param [ true, false ] is_negative Whether the value is negative.
      #
      # @return [ Array ] Tuple of the low and high bits.
      #
      # @since 4.2.0
      def parts_to_bits(significand, exponent, is_negative)
        validate_range!(exponent, significand)
        exponent = exponent + Decimal128::EXPONENT_OFFSET
        high = significand >> 64
        low = (high << 64) ^ significand

        if high >> 49 == 1
          high = high & 0x7fffffffffff
          high |= TWO_HIGHEST_BITS_SET
          high |= (exponent & 0x3fff) << 47
        else
          high |= exponent << 49
        end

        if is_negative
          high |= SIGN_BIT_MASK
        end


        [ low, high ]
      end

      private

      def validate_range!(exponent, significand)
        unless valid_exponent?(exponent)
          raise Decimal128::InvalidRange.new
        end

        unless valid_significand?(significand)
          raise Decimal128::UnrepresentablePrecision.new
        end
      end

      def valid_significand?(significand)
        significand.to_s.length <= Decimal128::MAX_DIGITS_OF_PRECISION
      end

      def valid_exponent?(exponent)
        exponent <= Decimal128::MAX_EXPONENT && exponent >= Decimal128::MIN_EXPONENT
      end

      # Helper class for parsing a String into Decimal128 high and low bits.
      #
      # @api private
      #
      # @since 4.2.0
      class FromString

        # Regex matching a string representing NaN.
        #
        # @return [ Regex ] A regex matching a NaN string.
        #
        # @since 4.2.0
        NAN_REGEX = /^(\-)?(S)?NaN$/i

        # Regex matching a string representing positive or negative Infinity.
        #
        # @return [ Regex ] A regex matching a positive or negative Infinity string.
        #
        # @since 4.2.0
        INFINITY_REGEX = /^(\+|\-)?Inf(inity)?$/i

        # Regex for the fraction, including leading zeros.
        #
        # @return [ Regex ] The regex for matching the fraction,
        #   including leading zeros.
        #
        # @since 4.2.0
        SIGNIFICAND_WITH_LEADING_ZEROS_REGEX = /(0*)(\d+)/

        # Regex for separating a negative sign from the significands.
        #
        # @return [ Regex ] The regex for separating a sign from significands.
        #
        # @since 4.2.0
        SIGN_AND_DIGITS_REGEX = /^(\-)?(\S+)/

        # Regex matching a scientific exponent.
        #
        # @return [ Regex ] A regex matching E, e, E+, e+.
        #
        # @since 4.2.0
        SCIENTIFIC_EXPONENT_REGEX = /E\+?/i

        # Regex for capturing trailing zeros.
        #
        # @since 4.2.0
        TRAILING_ZEROS_REGEX = /[1-9]*(0+)$/

        # Regex for a valid decimal128 string format.
        #
        # @return [ Regex ] The regex for a valid decimal128 string.
        #
        # @since 4.2.0
        VALID_DECIMAL128_STRING_REGEX = /^[\-\+]?(\d+(\.\d*)?|\.\d+)(E[\-\+]?\d+)?$/i

        # Initialize the FromString Builder object.
        #
        # @example Create the FromString builder.
        #   Builder::FromString.new(string)
        #
        # @param [ String ] string The string to create a Decimal128 from.
        #
        # @since 4.2.0
        def initialize(string)
          @string = string
        end

        # Get the bits representing the Decimal128 that the string corresponds to.
        #
        # @example Get the bits for the Decimal128 object created from the string.
        #   builder.bits
        #
        # @return [ Array ] Tuple of the low and high bits.
        #
        # @since 4.2.0
        def bits
          if special?
            to_special_bits
          else
            validate_format!
            to_bits
          end
        end

        private

        def to_bits
          original, sign, digits_str = SIGN_AND_DIGITS_REGEX.match(@string).to_a
          digits, e, scientific_exp = digits_str.partition(SCIENTIFIC_EXPONENT_REGEX)
          before_decimal, decimal, after_decimal = digits.partition('.')

          significand_str = before_decimal << after_decimal
          significand_str = SIGNIFICAND_WITH_LEADING_ZEROS_REGEX.match(significand_str).to_a[2]

          exponent = -(after_decimal.length)
          exponent = exponent + scientific_exp.to_i
          exponent, significand_str = round_exact(exponent, significand_str)
          exponent, significand_str = clamp(exponent, significand_str)

          Builder.parts_to_bits(significand_str.to_i, exponent, sign == '-')
        end

        def round_exact(exponent, significand)
          if exponent < Decimal128::MIN_EXPONENT
            if significand.to_i == 0
              round = Decimal128::MIN_EXPONENT - exponent
              exponent += round
            elsif trailing_zeros = TRAILING_ZEROS_REGEX.match(significand)
              round = [ (Decimal128::MIN_EXPONENT - exponent),
                        trailing_zeros[1].size ].min
              significand = significand[0...-round]
              exponent += round
            end
          elsif significand.length > Decimal128::MAX_DIGITS_OF_PRECISION
            trailing_zeros = TRAILING_ZEROS_REGEX.match(significand)
            if trailing_zeros
              round = [ trailing_zeros[1].size,
                        (significand.length - Decimal128::MAX_DIGITS_OF_PRECISION),
                        (Decimal128::MAX_EXPONENT - exponent)].min
              significand = significand[0...-round]
              exponent += round
            end
          end
          [ exponent, significand ]
        end

        def clamp(exponent, significand)
          if exponent > Decimal128::MAX_EXPONENT
            if significand.to_i == 0
              adjust = exponent - Decimal128::MAX_EXPONENT
              significand = '0'
            else
              adjust = [ (exponent - Decimal128::MAX_EXPONENT),
                         Decimal128::MAX_DIGITS_OF_PRECISION - significand.length ].min
              significand << '0'* adjust
            end
            exponent -= adjust
          end

          [ exponent, significand ]
        end

        def to_special_bits
          high = 0
          if match = NAN_REGEX.match(@string)
            high = NAN_MASK
            high = high | SIGN_BIT_MASK if match[1]
            high = high | SNAN_MASK if match[2]
          elsif match = INFINITY_REGEX.match(@string)
            high = INFINITY_MASK
            high = high | SIGN_BIT_MASK if match[1] == '-'
          end
          [ 0, high ]
        end

        def special?
          @string =~ NAN_REGEX || @string =~ INFINITY_REGEX
        end

        def validate_format!
          raise BSON::Decimal128::InvalidString.new unless @string =~ VALID_DECIMAL128_STRING_REGEX
        end
      end

      # Helper class for parsing a BigDecimal into Decimal128 high and low bits.
      #
      # @api private
      #
      # @since 4.2.0
      class FromBigDecimal

        # Initialize the FromBigDecimal Builder object.
        #
        # @example Create the FromBigDecimal builder.
        #   Builder::FromBigDecimal.new(big_decimal)
        #
        # @param [ BigDecimal ] big_decimal The big decimal object to
        #   create a Decimal128 from.
        #
        # @since 4.2.0
        def initialize(big_decimal)
          @big_decimal = big_decimal
        end

        # Get the bits representing the Decimal128 that the big decimal corresponds to.
        #
        # @example Get the bits for the Decimal128 object created from the big decimal.
        #   builder.bits
        #
        # @return [ Array ] Tuple of the low and high bits.
        #
        # @since 4.2.0
        def bits
          if special?
            to_special_bits
          else
            to_bits
          end
        end

        private

        def to_special_bits
          case @big_decimal.sign
            when ::BigDecimal::SIGN_POSITIVE_INFINITE
              high = INFINITY_MASK
            when ::BigDecimal::SIGN_NEGATIVE_INFINITE
              high = INFINITY_MASK | SIGN_BIT_MASK
            when ::BigDecimal::SIGN_NaN
              high = NAN_MASK
          end
          [ 0, high ]
        end

        def to_bits
          sign, significand_str, base, exp = @big_decimal.split
          exponent = @big_decimal.zero? ? 0 : exp - significand_str.length
          is_negative = (sign == ::BigDecimal::SIGN_NEGATIVE_FINITE || sign == ::BigDecimal::SIGN_NEGATIVE_ZERO)
          Builder.parts_to_bits(significand_str.to_i,
                                exponent,
                                is_negative)
        end

        def special?
          @big_decimal.infinite? || @big_decimal.nan?
        end
      end

      # Helper class for getting a String representation of a Decimal128 object.
      #
      # @api private
      #
      # @since 4.2.0
      class ToString

        # String representing a NaN value.
        #
        # @return [ String ] The string representing NaN.
        #
        # @since 4.2.0
        NAN_STRING = 'NaN'

        # String representing an Infinity value.
        #
        # @return [ String ] The string representing Infinity.
        #
        # @since 4.2.0
        INFINITY_STRING = 'Infinity'

        # Initialize the FromBigDecimal Builder object.
        #
        # @example Create the ToString builder.
        #   Builder::ToString.new(big_decimal)
        #
        # @param [ Decimal128 ] decimal128 The decimal128 object to
        #   create a String from.
        #
        # @since 4.2.0
        def initialize(decimal128)
          @decimal128 = decimal128
        end

        # Get the string representing the Decimal128 object.
        #
        # @example Get a string representing the decimal128.
        #   builder.string
        #
        # @return [ String ] The string representing the decimal128 object.
        #
        # @note The returned string may be frozen.
        #
        # @since 4.2.0
        def string
          return NAN_STRING if nan?
          str = infinity? ? INFINITY_STRING : create_string
          negative? ? "-#{str}" : str
        end

        private

        def create_string
          if use_scientific_notation?
            exp_pos_sign = exponent < 0 ? '' : '+'
            if significand.length > 1
              str = "#{significand[0]}.#{significand[1..-1]}E#{exp_pos_sign}#{scientific_exponent}"
            else
              str = "#{significand}E#{exp_pos_sign}#{scientific_exponent}"
            end
          elsif exponent < 0
            if significand.length > exponent.abs
              decimal_point_index = significand.length - exponent.abs
              str = "#{significand[0..decimal_point_index-1]}.#{significand[decimal_point_index..-1]}"
            else
              left_zero_pad = (exponent + significand.length).abs
              str = "0.#{'0' * left_zero_pad}#{significand}"
            end
          end
          str || significand
        end

        def scientific_exponent
          @scientific_exponent ||= (significand.length - 1) + exponent
        end

        def use_scientific_notation?
          exponent > 0 || scientific_exponent < -6
        end

        def exponent
          @exponent ||= two_highest_bits_set? ?
              ((high_bits & 0x1fffe00000000000) >> 47) - Decimal128::EXPONENT_OFFSET :
              ((high_bits & 0x7fff800000000000) >> 49) - Decimal128::EXPONENT_OFFSET
        end

        def significand
          @significand ||= two_highest_bits_set? ? '0' : bits_to_significand.to_s
        end

        def bits_to_significand
          significand = high_bits & 0x1ffffffffffff
          significand = significand << 64
          significand |= low_bits
        end

        def two_highest_bits_set?
          high_bits & TWO_HIGHEST_BITS_SET == TWO_HIGHEST_BITS_SET
        end

        def nan?
          high_bits & NAN_MASK == NAN_MASK
        end

        def negative?
          high_bits & SIGN_BIT_MASK == SIGN_BIT_MASK
        end

        def infinity?
          high_bits & INFINITY_MASK == INFINITY_MASK
        end

        def high_bits
          @decimal128.instance_variable_get(:@high)
        end

        def low_bits
          @decimal128.instance_variable_get(:@low)
        end
      end
    end
  end
end