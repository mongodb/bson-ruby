# Copyright (C) 2016 MongoDB Inc.
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

require "spec_helper"

describe BSON::Decimal128 do

  let(:low_bits) do
    decimal128.instance_variable_get(:@low)
  end

  let(:high_bits) do
    decimal128.instance_variable_get(:@high)
  end

  describe '#initialize' do

    context 'when the argument is neither a BigDecimal or String' do

      it 'raises an ArgumentError' do
        expect {
          described_class.new(:invalid)
        }.to raise_exception(ArgumentError)
      end
    end

    shared_examples_for 'an initialized BSON::Decimal128' do

      let(:decimal128) do
        described_class.new(argument)
      end

      let(:buffer) do
        decimal128.to_bson
      end

      let(:from_bson) do
        described_class.from_bson(buffer)
      end

      let(:expected_bson) do
        [expected_low_bits].pack(BSON::Int64::PACK) + [expected_high_bits].pack(BSON::Int64::PACK)
      end

      it 'sets the correct high order bits' do
        expect(high_bits).to eq(expected_high_bits)
      end

      it 'sets the correct low order bits' do
        expect(low_bits).to eq(expected_low_bits)
      end

      it 'serializes to bson' do
        expect(buffer.to_s).to eq(expected_bson)
      end

      it 'deserializes to the correct bits' do
        expect(from_bson.instance_variable_get(:@high)).to eq(expected_high_bits)
        expect(from_bson.instance_variable_get(:@low)).to eq(expected_low_bits)
      end
    end

    context 'when the object represents positive infinity' do

      let(:expected_high_bits) { 0x7800000000000000 }
      let(:expected_low_bits) { 0x0000000000000000 }

      context 'when a BigDecimal is passed' do

        let(:argument) { BigDecimal.new("Infinity") }

        it_behaves_like 'an initialized BSON::Decimal128'
      end

      context 'when a String is passed' do

        let(:argument) { "Infinity" }

        it_behaves_like 'an initialized BSON::Decimal128'
      end
    end

    context 'when the object represents negative infinity' do

      let(:expected_high_bits) { 0xf800000000000000 }
      let(:expected_low_bits) { 0x0000000000000000 }

      context 'when a BigDecimal is passed' do

        let(:argument) { BigDecimal.new("-Infinity") }

        it_behaves_like 'an initialized BSON::Decimal128'
      end

      context 'when a String is passed' do

        let(:argument) { "-Infinity" }

        it_behaves_like 'an initialized BSON::Decimal128'
      end
    end

    context 'when the object represents NaN' do

      let(:expected_high_bits) { 0x7c00000000000000 }
      let(:expected_low_bits) { 0x0000000000000000 }

      context 'when a BigDecimal is passed' do

        let(:argument) { BigDecimal.new("NaN") }

        it_behaves_like 'an initialized BSON::Decimal128'
      end

      context 'when a String is passed' do

        let(:argument) { "NaN" }

        it_behaves_like 'an initialized BSON::Decimal128'
      end
    end

    context 'when the object represents -NaN' do

      let(:expected_high_bits) { 0xfc00000000000000 }
      let(:expected_low_bits) { 0x0000000000000000 }

      context 'when a String is passed' do

        let(:argument) { "-NaN" }

        it_behaves_like 'an initialized BSON::Decimal128'
      end
    end

    context 'when the object represents SNaN' do

      let(:expected_high_bits) { 0x7e00000000000000 }
      let(:expected_low_bits) { 0x0000000000000000 }

      context 'when a String is passed' do

        let(:argument) { "SNaN" }

        it_behaves_like 'an initialized BSON::Decimal128'
      end
    end

    context 'when the object represents -SNaN' do

      let(:expected_high_bits) { 0xfe00000000000000 }
      let(:expected_low_bits) { 0x0000000000000000 }

      context 'when a String is passed' do

        let(:argument) { "-SNaN" }

        it_behaves_like 'an initialized BSON::Decimal128'
      end
    end

    context 'when the object represents -0' do

      let(:expected_high_bits) { 0xb040000000000000 }
      let(:expected_low_bits) { 0x0000000000000000 }

      context 'when a BigDecimal is passed' do

        let(:argument) { BigDecimal.new("-0") }

        it_behaves_like 'an initialized BSON::Decimal128'
      end

      context 'when a String is passed' do

        let(:argument) { "-0" }

        it_behaves_like 'an initialized BSON::Decimal128'
      end
    end

    context 'when the object represents a positive integer' do

      let(:expected_high_bits) { 0x3040000000000000 }
      let(:expected_low_bits) { 0x000000000000000c }

      context 'when a BigDecimal is passed' do

        let(:argument) { BigDecimal.new(12) }

        it_behaves_like 'an initialized BSON::Decimal128'
      end

      context 'when a String is passed' do

        let(:argument) { "12" }

        it_behaves_like 'an initialized BSON::Decimal128'
      end
    end

    context 'when the object represents a negative integer' do

      let(:expected_high_bits) { 0xb040000000000000 }
      let(:expected_low_bits) { 0x000000000000000c }

      context 'when a BigDecimal is passed' do

        let(:argument) { BigDecimal.new(-12) }

        it_behaves_like 'an initialized BSON::Decimal128'
      end

      context 'when a String is passed' do

        let(:argument) { "-12" }

        it_behaves_like 'an initialized BSON::Decimal128'
      end
    end

    context 'when the object represents a positive float' do

      let(:expected_high_bits) { 0x3036000000000000 }
      let(:expected_low_bits) { 0x0000000000003039 }

      context 'when a BigDecimal is passed' do

        let(:argument) { BigDecimal.new(0.12345, 5) }

        it_behaves_like 'an initialized BSON::Decimal128'
      end

      context 'when a String is passed' do

        let(:argument) { "0.12345" }

        it_behaves_like 'an initialized BSON::Decimal128'
      end
    end

    context 'when the object represents a negative float' do

      let(:expected_high_bits) { 0xb036000000000000 }
      let(:expected_low_bits) { 0x0000000000003039 }

      context 'when a BigDecimal is passed' do

        let(:argument) { BigDecimal.new(-0.12345, 5) }

        it_behaves_like 'an initialized BSON::Decimal128'
      end

      context 'when a String is passed' do

        let(:argument) { "-0.12345" }

        it_behaves_like 'an initialized BSON::Decimal128'
      end
    end

    context 'when the object represents a large positive integer' do

      let(:expected_high_bits) { 0x30403cde6fff9732 }
      let(:expected_low_bits) { 0xde825cd07e96aff2 }

      context 'when a BigDecimal is passed' do

        let(:argument) { BigDecimal.new(1234567890123456789012345678901234) }

        it_behaves_like 'an initialized BSON::Decimal128'
      end

      context 'when a String is passed' do

        let(:argument) { "1234567890123456789012345678901234" }

        it_behaves_like 'an initialized BSON::Decimal128'
      end
    end

    context 'when the object represents a large negative integer' do

      let(:expected_high_bits) { 0xb0403cde6fff9732 }
      let(:expected_low_bits) { 0xde825cd07e96aff2 }

      context 'when a BigDecimal is passed' do

        let(:argument) { BigDecimal.new(-1234567890123456789012345678901234) }

        it_behaves_like 'an initialized BSON::Decimal128'
      end

      context 'when a String is passed' do

        let(:argument) { "-1234567890123456789012345678901234" }

        it_behaves_like 'an initialized BSON::Decimal128'
      end
    end
  end

  context 'when deserializing' do

    context 'When the value has trailing zeroes' do

      let(:hex) do
        '18000000136400D0070000000000000000000000003A3000'
      end

      let(:packed) do
        [ hex ].pack('H*')
      end

      let(:buffer) do
        BSON::ByteBuffer.new(packed)
      end

      let(:decimal128) do
        BSON::Document.from_bson(buffer)['d']
      end

      let(:object_from_string) do
        BSON::Decimal128.from_string('2.000')
      end

      it 'has the correct high order' do
        expect(decimal128.instance_variable_get(:@high)).to eq(3475090062469758976)
      end

      it 'has the correct low order' do
        expect(decimal128.instance_variable_get(:@low)).to eq(2000)
      end

      it 'matches the object created from a string' do
        expect(object_from_string).to eq(decimal128)
      end
    end
  end

  describe '#from_string' do

    shared_examples_for 'a decimal128 initialized from a string' do

      let(:decimal128) do
        BSON::Decimal128.from_string(string)
      end

      let(:low_bits) do
        decimal128.instance_variable_get(:@low)
      end

      let(:high_bits) do
        decimal128.instance_variable_get(:@high)
      end

      it 'sets the correct high order bits' do
        expect(high_bits).to eq(expected_high_bits)
      end

      it 'sets the correct low order bits' do
        expect(low_bits).to eq(expected_low_bits)
      end
    end

    context 'when the string represents a special type' do

      context "when the string is 'NaN'" do

        let(:string) { 'NaN' }

        let(:expected_high_bits) { 0x7c00000000000000 }
        let(:expected_low_bits) { 0x0000000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-NaN'" do

        let(:string) { '-NaN' }

        let(:expected_high_bits) { 0xfc00000000000000 }
        let(:expected_low_bits) { 0x0000000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is 'SNaN'" do

        let(:string) { 'SNaN' }

        let(:expected_high_bits) { 0x7e00000000000000 }
        let(:expected_low_bits) { 0x0000000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-SNaN'" do

        let(:string) { '-SNaN' }

        let(:expected_high_bits) { 0xfe00000000000000 }
        let(:expected_low_bits) { 0x0000000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is 'Infinity'" do

        let(:string) { 'Infinity' }

        let(:expected_exponent) { nil }
        let(:expected_significand) { nil }
        let(:expected_high_bits) { 0x7800000000000000 }
        let(:expected_low_bits) { 0x0000000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-Infinity'" do

        let(:string) { '-Infinity' }

        let(:expected_exponent) { nil }
        let(:expected_significand) { nil }
        let(:expected_high_bits) { 0xf800000000000000 }
        let(:expected_low_bits) { 0x0000000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end
    end

    context 'when the string represents 0' do

      context "when the string is '0'" do

        let(:string) { '0' }

        let(:expected_exponent) { 0 }
        let(:expected_significand) { 0 }
        let(:expected_high_bits) { 0x3040000000000000 }
        let(:expected_low_bits) { 0 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-0'" do

        let(:string) { '-0' }

        let(:expected_exponent) { 0 }
        let(:expected_significand) { 0 }
        let(:expected_high_bits) { 0xb040000000000000 }
        let(:expected_low_bits) { 0 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '0.0'" do

        let(:string) { '0.0' }

        let(:expected_exponent) { -1 }
        let(:expected_significand) { 0 }
        let(:expected_high_bits) { 0x303e000000000000 }
        let(:expected_low_bits) { 0 }

        it_behaves_like 'a decimal128 initialized from a string'
      end
    end

    context 'when the string represents an integer' do

      context "when the string is '1'" do

        let(:string) { '1' }

        let(:expected_exponent) { 0 }
        let(:expected_significand) { 1 }
        let(:expected_high_bits) { 0x3040000000000000 }
        let(:expected_low_bits) { 0x1 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-1'" do

        let(:string) { '-1'}

        let(:expected_exponent) { 0 }
        let(:expected_significand) { 1 }
        let(:expected_high_bits) { 0xb040000000000000 }
        let(:expected_low_bits) { 0x1 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '20'" do

        let(:string) { '20' }

        let(:expected_exponent) { 0 }
        let(:expected_significand) { 20 }
        let(:expected_low_bits) { 0x14 }
        let(:expected_high_bits) { 0x3040000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-20'" do

        let(:string) { '-20' }

        let(:expected_exponent) { 0 }
        let(:expected_significand) { 20 }
        let(:expected_low_bits) { 0x14 }
        let(:expected_high_bits) { 0xb040000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '12345678901234567'" do

        let(:string) { '12345678901234567' }

        let(:expected_exponent) { 0 }
        let(:expected_significand) { 12345678901234567 }
        let(:expected_low_bits) { 0x002bdc545d6b4b87 }
        let(:expected_high_bits) { 0x3040000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-12345678901234567'" do

        let(:string) { '-12345678901234567' }

        let(:expected_exponent) { 0 }
        let(:expected_significand) { 12345678901234567 }
        let(:expected_low_bits) { 0x002bdc545d6b4b87 }
        let(:expected_high_bits) { 0xb040000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '12345689012345789012345'" do

        let(:string) { '12345689012345789012345' }

        let(:expected_exponent) { 0 }
        let(:expected_significand) { 12345689012345789012345 }
        let(:expected_low_bits) { 0x42da3a76f9e0d979 }
        let(:expected_high_bits) { 0x304000000000029d }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-12345689012345789012345'" do

        let(:string) { '-12345689012345789012345' }

        let(:expected_exponent) { 0 }
        let(:expected_significand) { 12345689012345789012345 }
        let(:expected_low_bits) { 0x42da3a76f9e0d979 }
        let(:expected_high_bits) { 0xb04000000000029d }

        it_behaves_like 'a decimal128 initialized from a string'
      end
    end

    context 'when the string represents a fraction' do

      context "when the string is '0.1'" do

        let(:string) { '0.1' }

        let(:expected_exponent) { -1 }
        let(:expected_significand) { 1 }
        let(:expected_low_bits) { 0x1 }
        let(:expected_high_bits) { 0x303e000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-0.1'" do

        let(:string) { '-0.1' }

        let(:expected_exponent) { -1 }
        let(:expected_significand) { 1 }
        let(:expected_low_bits) { 0x1 }
        let(:expected_high_bits) { 0xb03e000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '0.123'" do

        let(:string) { '0.123' }

        let(:expected_exponent) { -3 }
        let(:expected_significand) { 123 }
        let(:expected_low_bits) { 0x7b }
        let(:expected_high_bits) { 0x303a000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-0.123'" do

        let(:string) { '-0.123' }

        let(:expected_exponent) { -3 }
        let(:expected_significand) { 123 }
        let(:expected_low_bits) { 0x7b }
        let(:expected_high_bits) { 0xb03a000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '0.1234567890123456789012345678901234'" do

        let(:string) { '0.1234567890123456789012345678901234' }

        let(:expected_exponent) { -34 }
        let(:expected_significand) { 1234567890123456789012345678901234 }
        let(:expected_low_bits) { 0xde825cd07e96aff2 }
        let(:expected_high_bits) { 0x2ffc3cde6fff9732 }

        it_behaves_like 'a decimal128 initialized from a string'
      end
    end

    context 'when the string represents a fraction with a whole number' do

      context "when the string is '1.2'" do

        let(:string) { '1.2' }

        let(:expected_exponent) { -1 }
        let(:expected_significand) { 12 }
        let(:expected_low_bits) { 0xc }
        let(:expected_high_bits) { 0x303e000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-1.2'" do

        let(:string) { '-1.2' }

        let(:expected_exponent) { -1 }
        let(:expected_significand) { 12 }
        let(:expected_low_bits) { 0xc }
        let(:expected_high_bits) { 0xb03e000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '1.234'" do

        let(:string) { '1.234' }

        let(:expected_exponent) { -3 }
        let(:expected_significand) { 1234 }
        let(:expected_low_bits) { 0x4d2 }
        let(:expected_high_bits) { 0x303a000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-1.234'" do

        let(:string) { '-1.234' }

        let(:expected_exponent) { -3 }
        let(:expected_significand) { 1234 }
        let(:expected_low_bits) { 0x4d2 }
        let(:expected_high_bits) { 0xb03a000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '123456789.123456789'" do

        let(:string) { '123456789.123456789' }

        let(:expected_exponent) { -9 }
        let(:expected_significand) { 123456789123456789 }
        let(:expected_low_bits) { 0x1b69b4bacd05f15 }
        let(:expected_high_bits) { 0x302e000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-123456789.123456789'" do

        let(:string) { '-123456789.123456789' }

        let(:expected_exponent) { -9 }
        let(:expected_significand) { 123456789123456789 }
        let(:expected_low_bits) { 0x1b69b4bacd05f15 }
        let(:expected_high_bits) { 0xb02e000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end
    end

    context 'when the string represents a decimal with trailing zeros' do

      context "when the string is '1.000'" do

        let(:string) { '1.000' }

        let(:expected_exponent) { -3 }
        let(:expected_significand) { 1000 }
        let(:expected_low_bits) { 0x3e8 }
        let(:expected_high_bits) { 0x303a000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-1.000'" do

        let(:string) { '-1.000' }

        let(:expected_exponent) { -3 }
        let(:expected_significand) { 1000 }
        let(:expected_low_bits) { 0x3e8 }
        let(:expected_high_bits) { 0xb03a000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '100.000'" do

        let(:string) { '100.000' }

        let(:expected_exponent) { -3 }
        let(:expected_significand) { 100000 }
        let(:expected_low_bits) { 0x186a0 }
        let(:expected_high_bits) { 0x303a000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-100.000'" do

        let(:string) { '-100.000' }

        let(:expected_exponent) { -3 }
        let(:expected_significand) { 100000 }
        let(:expected_low_bits) { 0x186a0 }
        let(:expected_high_bits) { 0xb03a000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '1.234000000'" do

        let(:string) { '1.234000000' }

        let(:expected_exponent) { -9 }
        let(:expected_significand) { 1234000000 }
        let(:expected_low_bits) { 0x498d5880 }
        let(:expected_high_bits) { 0x302e000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-1.234000000'" do

        let(:string) { '-1.234000000' }

        let(:expected_exponent) { -9 }
        let(:expected_significand) { 1234000000 }
        let(:expected_low_bits) { 0x498d5880 }
        let(:expected_high_bits) { 0xb02e000000000000 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context 'when there are zeros following the decimal that are not trailing' do

        context "when the string is '0.001234'" do

          let(:string) { '0.001234' }

          let(:expected_exponent) { -6 }
          let(:expected_significand) { 1234 }
          let(:expected_low_bits) { 0x4d2 }
          let(:expected_high_bits) { 0x3034000000000000 }

          it_behaves_like 'a decimal128 initialized from a string'
        end
      end

      context 'when there are zeros following the decimal that are not trailing' do

        context "when the string is '0.00123400000'" do

          let(:string) { '0.00123400000' }

          let(:expected_exponent) { -11 }
          let(:expected_significand) { 123400000 }
          let(:expected_low_bits) { 0x75aef40 }
          let(:expected_high_bits) { 0x302a000000000000 }

          it_behaves_like 'a decimal128 initialized from a string'
        end
      end
    end

    context 'when the string uses scientific notation' do

      context 'when the exponent is positive' do

        context 'when the positive exponent is denoted with E' do

          context "when the string is '1.2E4'" do

            let(:string) { '1.2E4' }

            let(:expected_exponent) { 3 }
            let(:expected_significand) { 12 }
            let(:expected_low_bits) { 0xc }
            let(:expected_high_bits) { 0x3046000000000000 }

            it_behaves_like 'a decimal128 initialized from a string'
          end

          context "when the string is '-1.2E4'" do

            let(:string) { '-1.2E4' }

            let(:expected_exponent) { 3 }
            let(:expected_significand) { 12 }
            let(:expected_low_bits) { 0xc }
            let(:expected_high_bits) { 0xb046000000000000 }

            it_behaves_like 'a decimal128 initialized from a string'
          end
        end

        context 'when the positive exponent is denoted with E+' do

          context "when the string is '1.2E+4'" do

            let(:string) { '1.2E4' }

            let(:expected_exponent) { 3 }
            let(:expected_significand) { 12 }
            let(:expected_low_bits) { 0xc }
            let(:expected_high_bits) { 0x3046000000000000 }

            it_behaves_like 'a decimal128 initialized from a string'
          end

          context "when the string is '-1.2E+4'" do

            let(:string) { '-1.2E4' }

            let(:expected_exponent) { 3 }
            let(:expected_significand) { 12 }
            let(:expected_low_bits) { 0xc }
            let(:expected_high_bits) { 0xb046000000000000 }

            it_behaves_like 'a decimal128 initialized from a string'
          end
        end
      end

      context 'when the exponent is negative' do

        context "when the string is '1.2E-4'" do

          let(:string) { '1.2E-4' }

          let(:expected_exponent) { -5 }
          let(:expected_significand) { 12 }
          let(:expected_low_bits) { 0xc }
          let(:expected_high_bits) { 0x3036000000000000 }

          it_behaves_like 'a decimal128 initialized from a string'
        end

        context "when the string is '-1.2E-4'" do

          let(:string) { '-1.2E-4' }

          let(:expected_exponent) { -5 }
          let(:expected_significand) { 12 }
          let(:expected_low_bits) { 0xc }
          let(:expected_high_bits) { 0xb036000000000000 }

          it_behaves_like 'a decimal128 initialized from a string'
        end

        context 'when there are trailing zeros' do

          context "when the string is '1.200E-4'" do

            let(:string) { '1.200E-4' }

            let(:expected_exponent) { -7 }
            let(:expected_significand) { 1200 }
            let(:expected_low_bits) { 0x4b0 }
            let(:expected_high_bits) { 0x3032000000000000 }

            it_behaves_like 'a decimal128 initialized from a string'
          end

          context "when the string is '-1.200E-4'" do

            let(:string) { '-1.200E-4' }

            let(:expected_exponent) { -7 }
            let(:expected_significand) { 1200 }
            let(:expected_low_bits) { 0x4b0 }
            let(:expected_high_bits) { 0xb032000000000000 }

            it_behaves_like 'a decimal128 initialized from a string'
          end
        end
      end
    end
  end

  describe '#to_s' do

    shared_examples_for 'a decimal128 printed to a string' do

      let(:buffer) do
        buffer = BSON::ByteBuffer.new
        buffer.put_decimal128(low_bits, high_bits)
      end
      let(:decimal) { BSON::Decimal128.from_bson(buffer) }

      it 'prints the correct string' do
        expect(decimal.to_s).to eq(expected_string)
      end
    end

    context 'when the bits represent a special type' do

      context 'when the decimal is NaN' do

        let(:expected_string) { 'NaN' }
        let(:high_bits) { 0x7c00000000000000 }
        let(:low_bits) { 0x0 }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is negative NaN' do

        let(:expected_string) { 'NaN' }
        let(:high_bits) { 0xfc00000000000000 }
        let(:low_bits) { 0x0000000000000000 }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is SNaN' do

        let(:expected_string) { 'NaN' }
        let(:high_bits) { 0x7e00000000000000 }
        let(:low_bits) { 0x0000000000000000 }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is -SNaN' do

        let(:expected_string) { 'NaN' }
        let(:high_bits) { 0xfe00000000000000 }
        let(:low_bits) { 0x0000000000000000 }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is NaN with a payload' do

        let(:expected_string) { 'NaN' }
        let(:high_bits) { 0x7e00000000000000 }
        let(:low_bits) { 0x0000000000000008 }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is positive Infinity' do

        let(:expected_string) { 'Infinity' }
        let(:high_bits) { 0x7800000000000000 }
        let(:low_bits) { 0x0000000000000000 }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is negative Infinity' do

        let(:expected_string) { '-Infinity' }
        let(:high_bits) { 0xf800000000000000 }
        let(:low_bits) { 0x0000000000000000 }

        it_behaves_like 'a decimal128 printed to a string'
      end
    end

    context 'when the string represents an integer' do

      context 'when the decimal is 1' do

        let(:expected_string) { '1' }
        let(:high_bits) { 0x3040000000000000 }
        let(:low_bits) { 0x0000000000000001 }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is -1' do

        let(:expected_string) { '-1' }
        let(:high_bits) { 0xb040000000000000 }
        let(:low_bits) { 0x0000000000000001 }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is 20' do

        let(:expected_string) { '20' }
        let(:high_bits) { 0x3040000000000000 }
        let(:low_bits) { 0x0000000000000014 }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is -20' do

        let(:expected_string) { '-20' }
        let(:high_bits) { 0xb040000000000000 }
        let(:low_bits) { 0x0000000000000014 }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is 12345678901234567' do

        let(:expected_string) { '12345678901234567' }
        let(:high_bits) { 0x3040000000000000 }
        let(:low_bits) { 0x002bdc545d6b4b87 }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is -12345678901234567' do

        let(:expected_string) { '-12345678901234567' }
        let(:high_bits) { 0xb040000000000000 }
        let(:low_bits) { 0x002bdc545d6b4b87 }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is 12345689012345789012345' do

        let(:expected_string) { '12345689012345789012345' }
        let(:high_bits) { 0x304000000000029d }
        let(:low_bits) { 0x42da3a76f9e0d979 }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is -12345689012345789012345' do

        let(:expected_string) { '-12345689012345789012345' }
        let(:high_bits) { 0xb04000000000029d }
        let(:low_bits) { 0x42da3a76f9e0d979 }

        it_behaves_like 'a decimal128 printed to a string'
      end
    end

    context 'when the string represents a fraction' do

      context 'when the decimal is 0.1' do

        let(:expected_string) { '0.1' }
        let(:high_bits) { 0x303e000000000000 }
        let(:low_bits) { 0x0000000000000001 }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is -0.1' do

        let(:expected_string) { '-0.1' }
        let(:high_bits) { 0xb03e000000000000 }
        let(:low_bits) { 0x0000000000000001 }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is 0.123' do

        let(:expected_string) { '0.123' }
        let(:high_bits) { 0x303a000000000000 }
        let(:low_bits) { 0x000000000000007b }

        it_behaves_like 'a decimal128 printed to a string'
      end

      context 'when the decimal is -0.123' do

        let(:expected_string) { '-0.123' }
        let(:high_bits) { 0xb03a000000000000 }
        let(:low_bits) { 0x000000000000007b }

        it_behaves_like 'a decimal128 printed to a string'
      end
    end

    context 'when the decimal should have leading zeros' do

      let(:expected_string) { '0.001234' }
      let(:high_bits) { 0x3034000000000000 }
      let(:low_bits) { 0x00000000000004d2 }

      it_behaves_like 'a decimal128 printed to a string'
    end

    context 'when the decimal has trailing zeros' do

      let(:expected_string) { '2.000' }
      let(:high_bits) { 0x303a000000000000 }
      let(:low_bits) { 0x00000000000007d0 }

      it_behaves_like 'a decimal128 printed to a string'
    end
  end

  describe "#==" do

    context "when the high and low bits are identical" do

      let(:string) do
        '1.23'
      end

      let(:decimal128) do
        described_class.from_string(string)
      end

      let(:other_decimal) do
        described_class.from_string(string)
      end

      it "returns true" do
        expect(decimal128).to eq(other_decimal)
      end
    end

    context "when the high and low bits are different" do

      let(:string) do
        '1.23'
      end

      let(:decimal128) do
        described_class.from_string(string)
      end

      it "returns false" do
        expect(decimal128).to_not eq(described_class.new(BigDecimal.new('2.00')))
      end
    end

    context "when other is not a decimal128" do

      it "returns false" do
        expect(described_class.from_string('1')).to_not eq(nil)
      end
    end
  end

  describe "#===" do

    let(:decimal128) do
      described_class.new(BigDecimal.new('1.23'))
    end

    context "when comparing with another decimal128" do

      context "when the high and low bits are equal" do

        let(:other) do
          described_class.from_string(decimal128.to_s)
        end

        it "returns true" do
          expect(decimal128 === other).to be true
        end
      end

      context "when the high and low bits are not equal" do

        let(:other) do
          described_class.new(BigDecimal.new('1000.003'))
        end

        it "returns false" do
          expect(decimal128 === other).to be false
        end
      end
    end

    context "when comparing to an decimal128 class" do

      it "returns false" do
        expect(decimal128 === BSON::Decimal128).to be false
      end
    end

    context "when comparing with a non string or decimal128" do

      it "returns false" do
        expect(decimal128 === "test").to be false
      end
    end

    context "when comparing with a non decimal128 class" do

      it "returns false" do
        expect(decimal128 === String).to be false
      end
    end
  end

  describe "#as_json" do

    let(:object) do
      described_class.new(BigDecimal.new('1.23'))
    end

    it "returns the decimal128 with $numberDecimal key" do
      expect(object.as_json).to eq({ "$numberDecimal" => object.to_s })
    end

    it_behaves_like "a JSON serializable object"
  end

  describe "::BSON_TYPE" do

    it "returns 0x13" do
      expect(described_class::BSON_TYPE).to eq(19.chr)
    end
  end

  describe "#bson_type" do

    let(:code) do
      described_class.new(BigDecimal.new('1.23'))
    end

    it "returns 0x13" do
      expect(code.bson_type).to eq(described_class::BSON_TYPE)
    end
  end

  describe "#eql" do

    context "when high and low bits are identical" do

      let(:string) do
        '2.00'
      end

      let(:decimal128) do
        described_class.from_string(string)
      end

      let(:other_decimal) do
        described_class.from_string(string)
      end

      it "returns true" do
        expect(decimal128).to eql(other_decimal)
      end
    end

    context "when the high and low bit are different" do

      let(:string) do
        '2.00'
      end

      let(:decimal128) do
        described_class.from_string(string)
      end

      it "returns false" do
        expect(decimal128).to_not eql(described_class.new(BigDecimal.new('2')))
      end
    end

    context "when other is not a Decimal128" do

      it "returns false" do
        expect(described_class.from_string('2')).to_not eql(nil)
      end
    end
  end

  describe "#hash" do

    let(:decimal128) do
      described_class.new(BigDecimal.new('-1234E+33'))
    end

    it "returns a hash of the high and low bits" do
      expect(decimal128.hash).to eq(BSON::Decimal128.from_bson(decimal128.to_bson).hash)
    end
  end

  describe "#inspect" do

    let(:decimal128) do
      described_class.new(BigDecimal.new('1.23'))
    end

    it "returns the inspection with the decimal128 to_s" do
      expect(decimal128.inspect).to eq("BSON::Decimal128('#{decimal128.to_s}')")
    end
  end

  describe "#to_big_decimal" do

    shared_examples_for 'a decimal128 convertible to a Ruby BigDecimal' do

      let(:decimal128) do
        described_class.new(big_decimal)
      end

      it 'properly converts the Decimal128 to a BigDecimal' do
        expect(decimal128.to_big_decimal).to eq(expected_big_decimal)
      end
    end

    context 'when the Decimal128 is a special type' do

      context 'when the value is Infinity' do

        let(:big_decimal) do
          BigDecimal.new('Infinity')
        end

        let(:expected_big_decimal) do
          big_decimal
        end

        it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
      end

      context 'when the value is -Infinity' do

        let(:big_decimal) do
          BigDecimal.new('-Infinity')
        end

        let(:expected_big_decimal) do
          big_decimal
        end

        it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
      end
    end

    context 'when the value represents an Integer' do

      context 'when the value is 1' do

        let(:big_decimal) do
          BigDecimal.new(1)
        end

        let(:expected_big_decimal) do
          big_decimal
        end

        it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
      end

      context 'when the value is -1' do

        let(:big_decimal) do
          BigDecimal.new(-1)
        end

        let(:expected_big_decimal) do
          big_decimal
        end

        it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
      end

      context 'when the value is 20' do

        let(:big_decimal) do
          BigDecimal.new(20)
        end

        let(:expected_big_decimal) do
          big_decimal
        end

        it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
      end

      context 'when the value is -20' do

        let(:big_decimal) do
          BigDecimal.new(-20)
        end

        let(:expected_big_decimal) do
          big_decimal
        end

        it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
      end

      context 'when the value is 12345678901234567' do

        let(:big_decimal) do
          BigDecimal.new(12345678901234567)
        end

        let(:expected_big_decimal) do
          big_decimal
        end

        it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
      end

      context 'when the value is -12345678901234567' do

        let(:big_decimal) do
          BigDecimal.new(-12345678901234567)
        end

        let(:expected_big_decimal) do
          big_decimal
        end

        it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
      end

      context 'when the value is 12345689012345789012345' do

        let(:big_decimal) do
          BigDecimal.new(12345689012345789012345)
        end

        let(:expected_big_decimal) do
          big_decimal
        end

        it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
      end

      context 'when the value is -12345689012345789012345' do

        let(:big_decimal) do
          BigDecimal.new(-12345689012345789012345)
        end

        let(:expected_big_decimal) do
          big_decimal
        end

        it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
      end
    end

    context 'when the value has a fraction' do

      context 'when the value is 0.1' do

        let(:big_decimal) do
          BigDecimal.new(0.1, 1)
        end

        let(:expected_big_decimal) do
          big_decimal
        end

        it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
      end

      context 'when the value is -0.1' do

        let(:big_decimal) do
          BigDecimal.new(-0.1, 1)
        end

        let(:expected_big_decimal) do
          big_decimal
        end

        it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
      end

      context 'when the value is 0.123' do

        let(:big_decimal) do
          BigDecimal.new(0.123, 3)
        end

        let(:expected_big_decimal) do
          big_decimal
        end

        it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
      end

      context 'when the value is -0.123' do

        let(:big_decimal) do
          BigDecimal.new(-0.123, 3)
        end

        let(:expected_big_decimal) do
          big_decimal
        end

        it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
      end
    end

    context 'when the value has leading zeros' do

      let(:big_decimal) do
        BigDecimal.new(0.001234, 4)
      end

      let(:expected_big_decimal) do
        big_decimal
      end

      it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
    end

    context 'when the value has trailing zeros' do

      let(:big_decimal) do
        BigDecimal.new(2.000, 4)
      end

      let(:expected_big_decimal) do
        big_decimal
      end

      it_behaves_like 'a decimal128 convertible to a Ruby BigDecimal'
    end
  end

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(described_class::BSON_TYPE, 'field')
    end

    it "registers the type" do
      expect(registered).to eq(described_class)
    end
  end
end
