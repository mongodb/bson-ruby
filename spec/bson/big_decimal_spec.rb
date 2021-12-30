# Copyright (C) 2016-2021 MongoDB Inc.
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

describe BSON::BigDecimal do

  describe '#from_bson' do
    shared_examples_for 'a BSON::BigDecimal deserializer' do

      let(:decimal128) do
        BSON::Decimal128.new(argument)
      end

      let(:deserialized_big_decimal) do
        BigDecimal.from_bson(decimal128.to_bson)
      end

      let(:deserialized_decimal128) do
        BSON::Decimal128.from_bson(decimal128.to_bson)
      end

      it 'deserializes Decimal128 encoded bson correctly' do
        if deserialized_decimal128.to_s == "NaN"
          expect(deserialized_big_decimal.nan?).to be true
        else
          expect(deserialized_big_decimal).to eq(deserialized_decimal128.to_big_decimal)
        end
      end
    end

    context 'when Infinity is passed' do

      let(:argument) { "Infinity" }

      it_behaves_like 'a BSON::BigDecimal deserializer'
    end

    context 'when -Infinity is passed' do

      let(:argument) { "-Infinity" }

      it_behaves_like 'a BSON::BigDecimal deserializer'
    end

    context 'when NaN is passed' do

      let(:argument) { "NaN" }

      it_behaves_like 'a BSON::BigDecimal deserializer'
    end

    context 'when -NaN is passed' do
      let(:argument) { "-NaN" }

      it_behaves_like 'a BSON::BigDecimal deserializer'
    end

    context 'when SNaN is passed' do
      let(:argument) { "SNaN" }

      it_behaves_like 'a BSON::BigDecimal deserializer'
    end

    context 'when -SNaN is passed' do
      let(:argument) { "SNaN" }

      it_behaves_like 'a BSON::BigDecimal deserializer'
    end

    context 'when -0 is passed' do
      let(:argument) { "-0" }

      it_behaves_like 'a BSON::BigDecimal deserializer'
    end

    context 'when a positive integer is passed' do
      let(:argument) { "12" }

      it_behaves_like 'a BSON::BigDecimal deserializer'
    end

    context 'when a negative integer is passed' do
      let(:argument) { "-12" }

      it_behaves_like 'a BSON::BigDecimal deserializer'
    end

    context 'when a positive float is passed' do
      let(:argument) { "0.12345" }

      it_behaves_like 'a BSON::BigDecimal deserializer'
    end

    context 'when a negative float is passed' do
      let(:argument) { "-0.12345" }

      it_behaves_like 'a BSON::BigDecimal deserializer'
    end

    context 'when a large positive integer is passed' do
      let(:argument) { "1234567890123456789012345678901234" }

      it_behaves_like 'a BSON::BigDecimal deserializer'
    end

    context 'when a large negative integer is passed' do
      let(:argument) { "-1234567890123456789012345678901234" }

      it_behaves_like 'a BSON::BigDecimal deserializer'
    end
  end

  describe "#to_bson" do
    shared_examples_for 'a BSON::BigDecimal serializer' do

      let(:decimal128) do
        BSON::Decimal128.new(BigDecimal(argument).to_s)
      end

      let(:decimal_128_bson) do
        decimal128.to_bson
      end

      let(:big_decimal_bson) do
        BigDecimal(argument).to_bson
      end

      it 'serializes BigDecimals correctly' do
        expect(decimal_128_bson.to_s).to eq(big_decimal_bson.to_s)
      end
    end

    context 'when Infinity is passed' do

      let(:argument) { "Infinity" }

      it_behaves_like 'a BSON::BigDecimal serializer'
    end

    context 'when -Infinity is passed' do

      let(:argument) { "-Infinity" }

      it_behaves_like 'a BSON::BigDecimal serializer'
    end

    context 'when NaN is passed' do

      let(:argument) { "NaN" }

      it_behaves_like 'a BSON::BigDecimal serializer'
    end

    context 'when -0 is passed' do
      let(:argument) { "-0" }

      it_behaves_like 'a BSON::BigDecimal serializer'
    end

    context 'when a positive integer is passed' do
      let(:argument) { "12" }

      it_behaves_like 'a BSON::BigDecimal serializer'
    end

    context 'when a negative integer is passed' do
      let(:argument) { "-12" }

      it_behaves_like 'a BSON::BigDecimal serializer'
    end

    context 'when a positive float is passed' do
      let(:argument) { "0.12345" }

      it_behaves_like 'a BSON::BigDecimal serializer'
    end

    context 'when a negative float is passed' do
      let(:argument) { "-0.12345" }

      it_behaves_like 'a BSON::BigDecimal serializer'
    end

    context 'when a large positive integer is passed' do
      let(:argument) { "1234567890123456789012345678901234" }

      it_behaves_like 'a BSON::BigDecimal serializer'
    end

    context 'when a large negative integer is passed' do
      let(:argument) { "-1234567890123456789012345678901234" }

      it_behaves_like 'a BSON::BigDecimal serializer'
    end

    context "when passing an out of range Decimal128" do
      let(:argument) { "1E1000000" }

      it "raises an error" do
        expect do
          BigDecimal(argument).to_bson
        end.to raise_error(BSON::Decimal128::InvalidRange)
      end
    end

    context "when passing a number with too much precision for Decimal128" do
      let(:argument) { "1.000000000000000000000000000000000000000000000000001" }

      it "raises an error" do
        expect do
          BigDecimal(argument).to_bson
        end.to raise_error(BSON::Decimal128::UnrepresentablePrecision)
      end
    end
  end

  describe "#from_bson/#to_bson" do
    shared_examples_for 'a BSON::BigDecimal round trip' do

      let(:big_decimal) do
        BigDecimal(argument)
      end

      let(:big_decimal_bson) do
        big_decimal.to_bson
      end

      let(:deserialized_big_decimal) do
        BigDecimal.from_bson(big_decimal_bson)
      end

      it 'serializes BigDecimals correctly' do
        if big_decimal.nan?
          expect(deserialized_big_decimal.nan?).to be true
        else
          expect(deserialized_big_decimal).to eq(big_decimal)
        end
      end
    end

    context 'when Infinity is passed' do

      let(:argument) { "Infinity" }

      it_behaves_like 'a BSON::BigDecimal round trip'
    end

    context 'when -Infinity is passed' do

      let(:argument) { "-Infinity" }

      it_behaves_like 'a BSON::BigDecimal round trip'
    end

    context 'when NaN is passed' do

      let(:argument) { "NaN" }

      it_behaves_like 'a BSON::BigDecimal round trip'
    end

    context 'when -0 is passed' do
      let(:argument) { "-0" }

      it_behaves_like 'a BSON::BigDecimal round trip'
    end

    context 'when a positive integer is passed' do
      let(:argument) { "12" }

      it_behaves_like 'a BSON::BigDecimal round trip'
    end

    context 'when a negative integer is passed' do
      let(:argument) { "-12" }

      it_behaves_like 'a BSON::BigDecimal round trip'
    end

    context 'when a positive float is passed' do
      let(:argument) { "0.12345" }

      it_behaves_like 'a BSON::BigDecimal round trip'
    end

    context 'when a negative float is passed' do
      let(:argument) { "-0.12345" }

      it_behaves_like 'a BSON::BigDecimal round trip'
    end

    context 'when a large positive integer is passed' do
      let(:argument) { "1234567890123456789012345678901234" }

      it_behaves_like 'a BSON::BigDecimal round trip'
    end

    context 'when a large negative integer is passed' do
      let(:argument) { "-1234567890123456789012345678901234" }

      it_behaves_like 'a BSON::BigDecimal round trip'
    end
  end
end
