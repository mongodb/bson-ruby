# Copyright (C) 2009-2014 MongoDB Inc.
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

    shared_examples_for 'a decimal128 initialized from a Ruby BigDecimal' do

      let(:decimal128) do
        described_class.new(big_decimal)
      end

      let(:buffer) do
        decimal128.to_bson
      end

      let(:from_bson) do
        described_class.from_bson(buffer)
      end

      it 'sets the correct high order bits' do
        expect(high_bits).to eq(expected_high_bits)
      end

      it 'sets the correct low order bits' do
        expect(low_bits).to eq(expected_low_bits)
      end

      it 'serializes to bson' do
        expect(buffer.length).to eq(16)
      end

      it 'deserializes to the correct bits' do
        expect(from_bson.instance_variable_get(:@high)).to eq(high_bits)
        expect(from_bson.instance_variable_get(:@low)).to eq(low_bits)
      end
    end

    context 'when the exponent is out of range' do

      it 'raises an exception' do

      end
    end

    context 'when number is out of range' do

      it 'raises an exception' do

      end
    end

    context 'when passing a non-BigDecimal object' do

      it 'raises an exception' do

      end
    end

    context 'when the big decimal represents positive infinity' do

      let(:big_decimal) { BigDecimal.new("Infinity") }
      let(:expected_high_bits) { 0x7800000000000000 }
      let(:expected_low_bits) { 0 }

      it_behaves_like 'a decimal128 initialized from a Ruby BigDecimal'
    end

    context 'when the big decimal represents negative infinity' do

      let(:big_decimal) { BigDecimal.new("-Infinity") }
      let(:expected_high_bits) { 0xf800000000000000 }
      let(:expected_low_bits) { 0 }

      it_behaves_like 'a decimal128 initialized from a Ruby BigDecimal'
    end

    context 'when the big decimal represents NaN' do

      let(:big_decimal) { BigDecimal.new("NaN") }
      let(:expected_high_bits) { 0x7c00000000000000 }
      let(:expected_low_bits) { 0 }

      it_behaves_like 'a decimal128 initialized from a Ruby BigDecimal'
    end

    context 'when the big decimal represents a positive integer' do

      let(:big_decimal) { BigDecimal.new(1) }
      let(:expected_high_bits) { 0x3040000000000000 }
      let(:expected_low_bits) { 1 }

      it_behaves_like 'a decimal128 initialized from a Ruby BigDecimal'
    end

    context 'when the big decimal represents a negative integer' do

      let(:big_decimal) { BigDecimal.new(-1) }
      let(:expected_high_bits) { 0xb040000000000000 }
      let(:expected_low_bits) { 1 }

      it_behaves_like 'a decimal128 initialized from a Ruby BigDecimal'
    end

    context 'when the big decimal represents a positive float' do

      let(:big_decimal) { BigDecimal.new(0.12345, 5) }
      let(:expected_high_bits) { 0x3036000000000000 }
      let(:expected_low_bits) { 0x0000000000003039 }

      it_behaves_like 'a decimal128 initialized from a Ruby BigDecimal'
    end

    context 'when the big decimal represents a negative float' do

      let(:big_decimal) { BigDecimal.new(-0.12345, 5) }
      let(:expected_high_bits) { 0xb036000000000000 }
      let(:expected_low_bits) { 0x0000000000003039 }

      it_behaves_like 'a decimal128 initialized from a Ruby BigDecimal'
    end

    context 'when the big decimal represents a large positive integer' do

      let(:big_decimal) { BigDecimal.new(1234567890123456789012345678901234) }
      let(:expected_high_bits) { 0x30403cde6fff9732 }
      let(:expected_low_bits) { 0xde825cd07e96aff2 }

      it_behaves_like 'a decimal128 initialized from a Ruby BigDecimal'
    end

    context 'when the big decimal represents a large negative integer' do

      let(:big_decimal) { BigDecimal.new(-1234567890123456789012345678901234) }
      let(:expected_high_bits) { 0xb0403cde6fff9732 }
      let(:expected_low_bits) { 0xde825cd07e96aff2 }

      it_behaves_like 'a decimal128 initialized from a Ruby BigDecimal'
    end
  end

  context 'when deserializing' do

    context 'Trailing zeroes' do

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

      let(:from_string) do
        BSON::Decimal128.from_string('2.000')
      end

      it 'has the correct high order' do
        expect(decimal128.instance_variable_get(:@high)).to eq(3475090062469758976)
      end

      it 'has the correct low order' do
        expect(decimal128.instance_variable_get(:@low)).to eq(2000)
      end

      it 'matches the from_string' do
        expect(from_string).to eq(decimal128)
      end
    end
  end

  describe '#from_string' do

    shared_examples_for 'a decimal128 initialized from a string' do

      let(:decimal128) do
        described_class.from_string(string)
      end

      let(:exponent) do
        if decimal128.instance_variable_get(:@exponent)
          decimal128.instance_variable_get(:@exponent) - described_class::EXPONENT_OFFSET
        end
      end

      let(:significand) do
        decimal128.instance_variable_get(:@significand)
      end

      let(:low_bits) do
        decimal128.instance_variable_get(:@low)
      end

      let(:high_bits) do
        decimal128.instance_variable_get(:@high)
      end

      it 'sets the correct exponent' do
        expect(exponent).to eq(expected_exponent)
      end

      it 'sets the correct significand' do
        expect(significand).to eq(expected_significand)
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

        let(:expected_exponent) { nil }
        let(:expected_significand) { nil }
        let(:expected_high_bits) { 0x7c00000000000000 }
        let(:expected_low_bits) { 0 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is 'Infinity'" do

        let(:string) { 'Infinity' }

        let(:expected_exponent) { nil }
        let(:expected_significand) { nil }
        let(:expected_high_bits) { 0x7800000000000000 }
        let(:expected_low_bits) { 0 }

        it_behaves_like 'a decimal128 initialized from a string'
      end

      context "when the string is '-Infinity'" do

        let(:string) { '-Infinity' }

        let(:expected_exponent) { nil }
        let(:expected_significand) { nil }
        let(:expected_high_bits) { 0xf800000000000000 }
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

        let(:string) { '-1 '}

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

      context 'when the string does not have a leading 0' do

        context "when the string is '.1'" do

          let(:string) { '.1' }

          let(:expected_exponent) { -1 }
          let(:expected_significand) { 1 }
          let(:expected_low_bits) { 0x1 }
          let(:expected_high_bits) { 0x303e000000000000 }

          it_behaves_like 'a decimal128 initialized from a string'
        end

        context "when the string is '-.1'" do

          let(:string) { '-.1' }

          let(:expected_exponent) { -1 }
          let(:expected_significand) { 1 }
          let(:expected_low_bits) { 0x1 }
          let(:expected_high_bits) { 0xb03e000000000000 }

          it_behaves_like 'a decimal128 initialized from a string'
        end

        context "when the string is '.123'" do

          let(:string) { '.123' }

          let(:expected_exponent) { -3 }
          let(:expected_significand) { 123 }
          let(:expected_low_bits) { 0x7b }
          let(:expected_high_bits) { 0x303a000000000000 }

          it_behaves_like 'a decimal128 initialized from a string'
        end

        context "when the string is '-.123'" do

          let(:string) { '-.123' }

          let(:expected_exponent) { -3 }
          let(:expected_significand) { 123 }
          let(:expected_low_bits) { 0x7b }
          let(:expected_high_bits) { 0xb03a000000000000 }

          it_behaves_like 'a decimal128 initialized from a string'
        end
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

  # describe "#==" do
  #
  #   context "when data is identical" do
  #
  #     let(:string) do
  #
  #     end
  #
  #     let(:decimal128) do
  #       described_class.from_string(string)
  #     end
  #
  #     let(:other_decimal) do
  #       described_class.from_string(string)
  #     end
  #
  #     it "returns true" do
  #       expect(decimal128).to eq(other_decimal)
  #     end
  #   end
  #
  #   context "when the data is different" do
  #
  #     let(:string) do
  #
  #     end
  #
  #     let(:decimal128) do
  #       described_class.from_string(string)
  #     end
  #
  #     it "returns false" do
  #       expect(decimal128).to_not eq(described_class.new)
  #     end
  #   end
  #
  #   context "when other is not a decimal128" do
  #
  #     it "returns false" do
  #       expect(described_class.new).to_not eq(nil)
  #     end
  #   end
  # end
  #
  # describe "#===" do
  #
  #   let(:decimal128) do
  #     described_class.new
  #   end
  #
  #   context "when comparing with another decimal128" do
  #
  #     context "when the data is equal" do
  #
  #       let(:other) do
  #         described_class.from_string(decimal128.to_s)
  #       end
  #
  #       it "returns true" do
  #         expect(decimal128 === other).to be true
  #       end
  #     end
  #
  #     context "when the data is not equal" do
  #
  #       let(:other) do
  #         described_class.new
  #       end
  #
  #       it "returns false" do
  #         expect(decimal128 === other).to be false
  #       end
  #     end
  #   end
  #
  #   context "when comparing to an decimal128 class" do
  #
  #     it "returns false" do
  #       expect(decimal128 === BSON::Decimal128).to be false
  #     end
  #   end
  #
  #   context "when comparing with a string" do
  #
  #     context "when the data is equal" do
  #
  #       let(:other) do
  #         decimal128.to_s
  #       end
  #
  #       it "returns true" do
  #         expect(decimal128 === other).to be true
  #       end
  #     end
  #
  #     context "when the data is not equal" do
  #
  #       let(:other) do
  #         described_class.new.to_s
  #       end
  #
  #       it "returns false" do
  #         expect(decimal128 === other).to be false
  #       end
  #     end
  #   end
  #
  #   context "when comparing with a non string or decimal128" do
  #
  #     it "returns false" do
  #       expect(decimal128 === "test").to be false
  #     end
  #   end
  #
  #   context "when comparing with a non decimal128 class" do
  #
  #     it "returns false" do
  #       expect(decimal128 === String).to be false
  #     end
  #   end
  # end
  #
  # describe "#as_json" do
  #
  #   let(:object) do
  #     described_class.new
  #   end
  #
  #   it "returns the decimal128 with $numberDecimal key" do
  #     expect(object.as_json).to eq({ "$numberDecimal" => decimal128.to_s })
  #   end
  #
  #   it_behaves_like "a JSON serializable object"
  # end
  #
  # describe "::BSON_TYPE" do
  #
  #   it "returns 0x13" do
  #     expect(BSON::Decimal128::BSON_TYPE).to eq(19.chr)
  #   end
  # end
  #
  # describe "#bson_type" do
  #
  #   let(:code) do
  #     described_class.new
  #   end
  #
  #   it "returns 0x13" do
  #     expect(code.bson_type).to eq(BSON::Decimal128::BSON_TYPE)
  #   end
  # end
  #
  # describe "#eql" do
  #
  #   context "when data is identical" do
  #
  #     let(:string) do
  #
  #     end
  #
  #     let(:decimal128) do
  #       described_class.from_string(string)
  #     end
  #
  #     let(:other_decimal) do
  #       described_class.from_string(string)
  #     end
  #
  #     it "returns true" do
  #       expect(decimal128).to eql(other_decimal)
  #     end
  #   end
  #
  #   context "when the data is different" do
  #
  #     let(:string) do
  #
  #     end
  #
  #     let(:decimal128) do
  #       described_class.from_string(string)
  #     end
  #
  #     it "returns false" do
  #       expect(decimal128).to_not eql(described_class.new)
  #     end
  #   end
  #
  #   context "when other is not an object id" do
  #
  #     it "returns false" do
  #       expect(described_class.new).to_not eql(nil)
  #     end
  #   end
  # end
  #
  # describe ".from_string" do
  #
  #   context "when the string is valid" do
  #
  #     let(:string) do
  #       "4e4d66343b39b68407000001"
  #     end
  #
  #     let(:decimal128) do
  #       described_class.from_string(string)
  #     end
  #
  #     it "initializes with the string's bytes" do
  #       expect(decimal128.to_s).to eq(string)
  #     end
  #   end
  #
  #   context "when the string is not valid" do
  #
  #     it "raises an error" do
  #       expect {
  #         described_class.from_string("asadsf")
  #       }.to raise_error(BSON::Decimal128::Invalid)
  #     end
  #   end
  # end
  #
  # describe "#hash" do
  #
  #   let(:decimal128) do
  #     described_class.new
  #   end
  #
  #   it "returns a hash of the raw bytes" do
  #     expect(decimal128.hash).to eq(decimal128.to_bson.to_s.hash)
  #   end
  # end
  #
  # describe "#initialize" do
  #
  #   # @todo
  # end
  #
  # describe "#inspect" do
  #
  #   let(:decimal128) do
  #     described_class.new
  #   end
  #
  #   it "returns the inspection with the decimal128 id to_s" do
  #     expect(decimal128.inspect).to eq("BSON::Decimal128('#{decimal128.to_s}')")
  #   end
  #
  #   it "returns a string that evaluates into an equivalent decimal128 id" do
  #     expect(eval decimal128.inspect).to eq decimal128
  #   end
  # end
  #
  # describe ".legal?" do
  #
  #   context "when the string is too short to be an decimal128" do
  #
  #     it "returns false" do
  #       expect(described_class).to_not be_legal("a" * 23)
  #     end
  #   end
  #
  #   context "when checking against another decimal128 id" do
  #
  #     let(:decimal128) do
  #       described_class.new
  #     end
  #
  #     it "returns true" do
  #       expect(described_class).to be_legal(decimal128)
  #     end
  #   end
  # end
  #
  # # describe "#marshal_dump" do
  # #
  # #   let(:decimal128) do
  # #     described_class.new
  # #   end
  # #
  # #   let(:dumped) do
  # #     Marshal.dump(decimal128)
  # #   end
  # #
  # #   it "dumps the raw bytes data" do
  # #     expect(Marshal.load(dumped)).to eq(decimal128)
  # #   end
  # # end
  # #
  # # describe "#marshal_load" do
  # #
  # #   context "when the object id was dumped in the old format" do
  # #
  # #     let(:legacy) do
  # #       "\x04\bo:\x13BSON::ObjectId\x06:\n" +
  # #           "@data[\x11iUi\x01\xE2i,i\x00i\x00i\x00i\x00i\x00i\x00i\x00i\x00i\x00"
  # #     end
  # #
  # #     let(:object_id) do
  # #       Marshal.load(legacy)
  # #     end
  # #
  # #     let(:expected) do
  # #       described_class.from_time(Time.utc(2013, 1, 1))
  # #     end
  # #
  # #     it "properly loads the object id" do
  # #       expect(object_id).to eq(expected)
  # #     end
  # #
  # #     it "removes the bad legacy data" do
  # #       object_id.to_bson
  # #       expect(object_id.instance_variable_get(:@data)).to be_nil
  # #     end
  # #   end
  # # end
  #
  # describe "#to_bson/#from_bson" do
  #
  #   let(:obj)  { described_class.from_string(string) }
  #   let(:bson) { obj.to_bson.to_s }
  #
  #   it_behaves_like "a bson element"
  #   it_behaves_like "a serializable bson element"
  #   it_behaves_like "a deserializable bson element"
  # end
  #
  # describe "#to_s" do
  #
  #   let(:string) do
  #
  #   end
  #
  #   let(:expected) do
  #     ""
  #   end
  #
  #   let(:decimal128) do
  #     described_class.from_string(string)
  #   end
  #
  #   it "" do
  #   end
  #
  #   it "returns the string in UTF-8" do
  #     expect(decimal128.to_s.encoding).to eq(Encoding.find(BSON::UTF8))
  #   end
  #
  #   it "converts to a readable yaml string" do
  #     expect(YAML.dump(decimal128.to_s)).to include(expected)
  #   end
  # end
  #
  # context "when the class is loaded" do
  #
  #   let(:registered) do
  #     BSON::Registry.get(BSON::Decaiml128::BSON_TYPE, 'field')
  #   end
  #
  #   it "registers the type" do
  #     expect(registered).to eq(described_class)
  #   end
  # end
  #
  # context "when the ids are used as keys" do
  #
  #   let(:decimal128) do
  #     described_class.new
  #   end
  #
  #   let(:hash) do
  #     { decimal128 => 1 }
  #   end
  #
  #   it "raises an exception on serialization" do
  #     expect {
  #       hash.to_bson
  #     }.to raise_error(BSON::InvalidKey)
  #   end
  # end
end
