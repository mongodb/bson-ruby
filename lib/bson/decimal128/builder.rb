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
  class Decimal128

    # Helper module for parsing string, big decimal, and decimal128 objects into
    # other objects.
    #
    # @since 4.1.0
    module Builder

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

      # The two highest bits of the 64 high order bits.
      #
      # @since 4.1.0
      TWO_HIGHEST_BITS_SET = (3 << 61).freeze

      extend self

      # Convert parts representing a Decimal128 into the corresponding bits.
      #
      # @param [ Integer ] significand The significand.
      # @param [ Integer ] exponent The exponent.
      # @param [ true, false ] is_negative Whether the value is negative.
      #
      # @return [ Array ] Tuple of the low and high bits.
      #
      # @since 4.1.0
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
        unless valid_significand?(significand) && valid_exponent?(exponent)
          raise Decimal128::InvalidRange.new(exponent, significand)
        end
      end

      def valid_significand?(significand)
        significand.to_s.length <= Decimal128::MAX_DIGITS_OF_PRECISION
      end

      def valid_exponent?(exponent)
        exponent <= Decimal128::MAX_EXPONENT && exponent >= Decimal128::MIN_EXPONENT
      end

      class FromString

        # Regex matching a string representing NaN.
        #
        # @return [ Regex ] A regex matching a NaN string.
        #
        # @since 4.1.0
        NAN_REGEX = /^(\-)?NaN$/i.freeze

        # Regex matching a string representing positive or negative Infinity.
        #
        # @return [ Regex ] A regex matching a positive or negative Infinity string.
        #
        # @since 4.1.0
        INFINITY_REGEX = /^(\+|\-)?Inf(inity)?$/i.freeze

        # Regex for the fraction, including leading zeros.
        #
        # @return [ Regex ] The regex for matching the fraction,
        #   including leading zeros.
        #
        # @since 4.1.0
        SIGNIFICAND_WITH_LEADING_ZEROS = /(0*)(\d+)/.freeze

        # Regex for separating a negative sign from the significands.
        #
        # @return [ Regex ] The regex for separating a sign from significands.
        #
        # @since 4.1.0
        SIGN_DIGITS_SEPARATOR = /^(\-)?(\S+)/.freeze

        # Regex matching a scientific exponent.
        #
        # @return [ Regex ] A regex matching E, e, E+, e+.
        #
        # @since 4.1.0
        SCIENTIFIC_EXPONENT_REGEX = /E\+?/i.freeze

        # Regex for capturing the significands.
        #
        # @since 4.1.0
        SIGNIFICANDS_REGEX = /^(0*)(\d*)/.freeze

        # Regex for a valid decimal128 string format.
        #
        # @return [ Regex ] The regex for a valid decimal128 string.
        #
        # @since 4.1.0
        VALID_DECIMAL128_STRING_REGEX = /^[\-\+]?(\d+(\.\d*)?|\.\d+)(E[\-\+]?\d+)?$/i.freeze

        # Initialize the FromString Builder object.
        #
        # @example Create the FromString builder.
        #   Builder::FromString.new(string)
        #
        # @param [ String ] string The string to create a Decimal128 from.
        #
        # @since 4.1.0
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
        # @since 4.1.0
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
          original, sign, digits_str = SIGN_DIGITS_SEPARATOR.match(@string).to_a
          digits, e, scientific_exp = digits_str.partition(SCIENTIFIC_EXPONENT_REGEX)
          before_decimal, decimal, after_decimal = digits.partition('.')

          significand_str = before_decimal << after_decimal
          significand_str = SIGNIFICAND_WITH_LEADING_ZEROS.match(significand_str).to_a[2]

          exponent = -(after_decimal.length)
          exponent = exponent + scientific_exp.to_i
          exponent, significand_str = round_exact(exponent, significand_str)
          exponent, significand_str = clamp(exponent, significand_str)

          Builder.parts_to_bits(significand_str.to_i, exponent, sign == '-')
        end

        def round_exact(exponent, significand)
          if exponent < Decimal128::MIN_EXPONENT
            while exponent < Decimal128::MIN_EXPONENT && significand[-1] == '0'
              exponent += 1
              significand.slice!('0') unless significand == '0'
            end
          elsif significand.length > Decimal128::MAX_DIGITS_OF_PRECISION
            while significand.length > Decimal128::MAX_DIGITS_OF_PRECISION && significand[-1] == '0' && exponent < Decimal128::MAX_EXPONENT
              exponent += 1
              significand.slice!('0') unless significand == '0'
            end
          end
          [ exponent, significand ]
        end

        def clamp(exponent, significand)
          if exponent > Decimal128::MAX_EXPONENT
            while exponent > Decimal128::MAX_EXPONENT && significand.length < Decimal128::MAX_DIGITS_OF_PRECISION
              exponent -= 1
              significand << '0' unless significand == '0'
            end
          end

          [ exponent, significand ]
        end

        def to_special_bits
          high = 0
          if match = NAN_REGEX.match(@string)
            high = NAN_MASK
            high = high | SIGN_BIT_MASK if match[1]
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

      class FromBigDecimal

        # Initialize the FromBigDecimal Builder object.
        #
        # @example Create the FromBigDecimal builder.
        #   Builder::FromBigDecimal.new(big_decimal)
        #
        # @param [ BigDecimal ] big_decimal The big decimal object to
        #   create a Decimal128 from.
        #
        # @since 4.1.0
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
        # @since 4.1.0
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
            when BigDecimal::SIGN_POSITIVE_INFINITE
              high = INFINITY_MASK
            when BigDecimal::SIGN_NEGATIVE_INFINITE
              high = INFINITY_MASK | SIGN_BIT_MASK
            when BigDecimal::SIGN_NaN
              high = NAN_MASK
          end
          [ 0, high ]
        end

        def to_bits
          sign, significand_str, base, exp = @big_decimal.split
          exponent = exp - significand_str.length
          Builder.parts_to_bits(significand_str.to_i,
                                exponent,
                                @big_decimal.sign == BigDecimal::SIGN_NEGATIVE_FINITE)
        end

        def special?
          @big_decimal.infinite? || @big_decimal.nan?
        end
      end

      class ToString

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

        # Initialize the FromBigDecimal Builder object.
        #
        # @example Create the ToString builder.
        #   Builder::ToString.new(big_decimal)
        #
        # @param [ Decimal128 ] decimal128 The decimal128 object to
        #   create a String from.
        #
        # @since 4.1.0
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
        # @since 4.1.0
        def string
          return NAN_STRING if nan?
          str = infinity? ? INFINITY_STRING : create_string
          negative? ? '-' << str : str
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