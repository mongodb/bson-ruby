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

    INFINITY_MASK = 0x7800000000000000

    NAN_MASK = 0x7c00000000000000

    SIGN_BIT_MASK = 1 << 63

    EXPONENT_OFFSET = 6176

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

    # Check case equality on the decimal object.
    #
    # @example Check case equality.
    #   decimal === other
    #
    # @param [ Object ] other The object to check against.
    #
    # @return [ true, false ] If the objects are equal in a case.
    #
    # @since 2.0.0
    def ===(other)
      # @todo
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

    # Create a new Decimal128 from a BigDecimal object.
    #
    # @example Create a Decimal128 from a BigDecimal.
    #   Decimal128.new(number)
    #
    # @param [ BigDecimal ] big_decimal The BigDecimal to use in
    #   instantiating a Decimal128.
    #
    # @since 4.1.0
    def initialize(value)
      raise Exception unless value.is_a?(BigDecimal)
      if special?(value)
        set_special_values(value)
      else
        parts = value.split
        exponent = parts[3]
        exponent  = exponent - parts[1].length
        set_bits(parts[1], exponent, value.sign == BigDecimal::SIGN_NEGATIVE_FINITE)
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
      # @todo
    end

    # Get a nice string for use with object inspection.
    #
    # @example Inspect the decimal object.
    #   decimal.inspect
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
    # @return [ String ] The raw bytes.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 4.1.0
    def to_bson(buffer = ByteBuffer.new)
      buffer.put_uint64(@low)
      buffer.put_uint64(@high)
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
      #binding.pry
      "high: #{@high} and low: #{@low}"
      # @todo
      #...force_encoding(UTF8)
    end
    alias :to_str :to_s

    # Raised when trying to create a deciaml128 with invalid data.
    #
    # @since 2.0.0
    class Invalid < RuntimeError; end

    private

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

    def set_bits(significand_str, exponent, negative = false)
      validate_range!(significand_str)
      set_exponent!(significand_str, exponent)
      set_high_low_bits(significand_str, negative)
    end

    def special?(decimal)
      decimal.infinite? || decimal.nan?
    end

    def set_high_low_bits(significand_str, negative = false)
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

      if negative
        @high |= SIGN_BIT_MASK
      end
    end

    def set_exponent!(significand_str, exponent)
      validate_exponent!(exponent)
      @exponent = exponent + EXPONENT_OFFSET
    end

    def validate_range!(significand_str)

    end

    def validate_exponent!(exp)

    end

    def get_low_bits(significand)
      low = 0
      bit_length = [significand.bit_length, 64].min
      0.upto(bit_length-1) do |i|
        if significand[i] == 1
          low |= 1 << i
        end
      end
      low
    end

    def get_high_bits(significand)
      high = 0
      # todo check upto
      64.upto(significand.bit_length-1) do |i|
        if significand[i] == 1
          high |= 1 << (i - 64)
        end
      end
      high
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
        decimal.instance_variable_set(:@low, buffer.get_uint64)
        decimal.instance_variable_set(:@high, buffer.get_uint64)
        decimal
      end

      # Create a new decimal128 from a string.
      #
      # @example Create a decimal128 from the string.
      #   BSON::Decimal128.from_string("1.05E+3")
      #
      # @param [ String ] string The string to create the decimal from.
      #
      # @raise [ BSON::Decimal128::Invalid ] If the provided string is invalid.
      #
      # @return [ BSON::Decimal128 ] The new decimal128.
      #
      # @since 2.0.0
      def from_string(string)
        unless legal_string?(string)
          raise Invalid.new("'#{string}' is an invalid Decimal128 string format.")
        end

        if (string =~ /\d+/).nil?
          new(BigDecimal(string))
        else
          empty, negative, string = /^(\-)?(\S+)/.match(string).to_a

          # handle scientific
          digits, e, sci_exp = string.partition(/E\+?/)
          before_decimal, d, after_decimal = digits.partition('.')

          if before_decimal.to_i > 0
            significant_digits = before_decimal << after_decimal
            exponent = -(after_decimal.length)
          else
            significant_digits = after_decimal.slice(/(0*)(\d+)/, 2)
            exponent = -(after_decimal.length)
          end

          exponent = exponent + sci_exp.to_i

          decimal = allocate
          decimal.send(:set_bits, significant_digits, exponent, negative)
          decimal
        end
      end

      # Determine if the provided string is a legal decimal128.
      #
      # @example Is the string a legal decimal128?
      #   BSON::Decimal128.legal?(string)
      #
      # @param [ String ] The string to check.
      #
      # @return [ true, false ] If the string is legal.
      #
      # @since 2.0.0
      def legal_string?(string)
       # @todo
        true
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
