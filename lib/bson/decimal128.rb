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
require 'bson/decimal128/builder'

module BSON

  class Decimal128

    # A Decimal128 is type 0x13 in the BSON spec.
    #
    # @since 4.1.0
    BSON_TYPE = 19.chr.force_encoding(BINARY).freeze

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

    # Maximum digits of precision.
    #
    # @since 4.1.0
    MAX_DIGITS_OF_PRECISION = 34.freeze

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

    # Create a new Decimal128 from a BigDecimal.
    #
    # @example Create a Decimal128 from a BigDecimal.
    #   Decimal128.new(big_decimal)
    #
    # @param [ BigDecimal ] big_decimal The BigDecimal to use for
    #   instantiating a Decimal128.
    #
    # @raise [ InvalidBigDecimal ] Raise error unless object argument is a BigDecimal.
    #
    # @since 4.1.0
    def initialize(big_decimal)
      raise InvalidBigDecimal.new unless big_decimal.is_a?(BigDecimal)
      set_bits(*Builder::FromBigDecimal.new(big_decimal).bits)
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

    # Get the string representation of the decimal128.
    #
    # @example Get the decimal128 as a string.
    #   decimal128.to_s
    #
    # @return [ String ] The decimal128 as a string.
    #
    # @since 4.1.0
    def to_s
      @string ||= Builder::ToString.new(self).string
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
      @big_decimal ||= BigDecimal.new(to_s)
    end

    private

    def set_bits(low, high)
      @low = low
      @high = high
    end

    class << self

      # Deserialize the decimal128 from raw BSON bytes.
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
        from_bits(*buffer.get_decimal128_bytes.unpack('Q*'))
      end

      # Instantiate a Decimal128 from a string.
      #
      # @example Create a Decimal128 from a string.
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
        from_bits(*Builder::FromString.new(string).bits)
      end

      # Instantiate a Decimal128 from a BigDecimal.
      #
      # @example Create a Decimal128 object from a BigDecimal.
      #   BSON::Decimal128.from_big_decimal(big_decimal)
      #
      # @param [ BigDecimal ] big_decimal The big decimal to instantiate the
      #   Decimal128 from.
      #
      # @raise [ BSON::Decimal128::InvalidBigDecimal ] If the provided value is not a
      #   BigDecimal.
      #
      # @return [ BSON::Decimal128 ] The new decimal128.
      #
      # @since 4.1.0
      def from_big_decimal(big_decimal)
        new(big_decimal)
      end

      # Instantiate a Decimal128 from a high and low bits.
      #
      # @example Create a Decimal128 from high and low bits.
      #   BSON::Decimal128.from_bits(high, low)
      #
      # @param [ Integer ] high The high order bits.
      # @param [ Integer ] low The low order bits.
      #
      # @return [ BSON::Decimal128 ] The new decimal128.
      #
      # @since 4.1.0
      def from_bits(low, high)
        decimal = allocate
        decimal.send(:set_bits, low, high)
        decimal
      end
    end

    # Raised when a Decimal128 is instantiated with a non-BigDecimal type.
    #
    # @since 4.1.0
    class InvalidBigDecimal < RuntimeError; end

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
    class InvalidRange < RuntimeError

      # Create an InvalidRange error.
      #
      # @example Create the error.
      #   InvalidRange.new(exponent, significand)
      #
      # @param [ Integer ] exponent The provided exponent.
      # @param [ Integer ] significand The provided significand.
      #
      # @since 4.1.0
      def initialize(exponent, significand)
        @exponent = exponent
        @significand = significand
      end

      # Get the custom error message for the exception.
      #
      # @example Get the message.
      #   error.message
      #
      # @return [ String ] The error message.
      #
      # @since 4.1.0
      def message
        "Value out of range for Decimal128 representation. The exponent provided (#{@exponent}) " +
          "must be at least #{Decimal128::MIN_EXPONENT} and no greater than " +
          "#{Decimal128::MAX_EXPONENT}. The provided significand (#{@significand}) can only have " +
          "up to 34 digits of precision."
      end
    end

    Registry.register(BSON_TYPE, self)
  end
end