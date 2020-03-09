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

require "spec_helper"

describe BSON::Int32 do

  describe "#intiialize" do

    let(:obj) { described_class.new(integer) }

    context "when the integer is 32-bit" do

      let(:integer) { Integer::MAX_32BIT }

      it "wraps the integer" do
        expect(obj.value).to be(integer)
      end
    end

    context "when the integer is too large" do

      let(:integer) { Integer::MAX_32BIT + 1 }

      it "raises an out of range error" do
        expect do
          obj
        end.to raise_error(RangeError, /#{integer} cannot be stored in 32 bits/)
      end
    end

    context "when the integer is too small" do

      let(:integer) { Integer::MIN_32BIT - 1 }

      it "raises an out of range error" do
        expect {
          obj
        }.to raise_error(RangeError)
      end
    end

    context 'when argument is an Int32' do
      let(:integer) do
        described_class.new(described_class.new(50))
      end

      it 'works' do
        expect(integer.value).to be 50
      end
    end
  end

  describe "#from_bson" do

    let(:type) { 16.chr }
    let(:obj)  { 123 }
    let(:bson) { [ obj ].pack(BSON::Int32::PACK) }

    it_behaves_like "a bson element"
    it_behaves_like "a deserializable bson element"
  end

  describe "when the integer is negative" do

    let(:decoded) { -1 }
    let(:encoded) { BSON::ByteBuffer.new([ -1 ].pack(BSON::Int32::PACK)) }
    let(:decoded_2) { -50 }
    let(:encoded_2) { BSON::ByteBuffer.new([ -50 ].pack(BSON::Int32::PACK)) }

    it "decodes a -1 correctly" do
      expect(BSON::Int32.from_bson(encoded)).to eq(decoded)
    end

    it "decodes a -50 correctly" do
      expect(BSON::Int32.from_bson(encoded_2)).to eq(decoded_2)
    end
  end

  describe "#to_bson" do

    context "when the integer is 32 bit" do

      let(:type) { 16.chr }
      let(:obj)  { BSON::Int32.new(Integer::MAX_32BIT - 1) }
      let(:bson) { [ Integer::MAX_32BIT - 1 ].pack(BSON::Int32::PACK) }

      it_behaves_like "a serializable bson element"
    end
  end

  describe "#to_bson_key" do

    let(:obj)  {  BSON::Int32.new(Integer::MAX_32BIT - 1) }
    let(:encoded) { (Integer::MAX_32BIT - 1) }

    it "returns the key as an integer" do
      expect(obj.to_bson_key).to eq(encoded)
    end
  end

  describe "#==" do

    let(:object) do
      described_class.new(1)
    end

    context "when data is identical" do

      let(:other_object) do
        described_class.new(1)
      end

      it "returns true" do
        expect(object).to eq(other_object)
      end

      context "other object is of another integer type" do

        let(:other_object) do
          BSON::Int64.new(1)
        end

        it "returns false" do
          expect(object).not_to eq(other_object)
        end
      end
    end

    context "when the data is different" do

      let(:other_object) do
        described_class.new(2)
      end

      it "returns false" do
        expect(object).not_to eq(other_object)
      end
    end

    context "when other is not a BSON integer" do

      it "returns false" do
        expect(described_class.new(1)).to_not eq('1')
      end
    end
  end

  describe "#===" do

    let(:object) do
      described_class.new(1)
    end

    context "when comparing with another BSON int32" do

      context "when the data is equal" do

        let(:other_object) do
          described_class.new(1)
        end

        it "returns true" do
          expect(object === other_object).to be true
        end

        context "other object is of another integer type" do

          let(:other_object) do
            BSON::Int64.new(1)
          end

          it "returns false" do
            expect(object === other_object).to be false
          end
        end
      end

      context "when the data is not equal" do

        let(:other_object) do
          described_class.new(2)
        end

        it "returns false" do
          expect(object === other_object).to be false
        end
      end
    end

    context "when comparing to an object id class" do

      it "returns false" do
        expect(described_class.new(1) === described_class).to be false
      end
    end

    context "when comparing with a string" do

      context "when the data is equal" do

        let(:other) do
          '1'
        end

        it "returns false" do
          expect(object === other).to be false
        end
      end

      context "when the data is not equal" do

        let(:other) do
          '2'
        end

        it "returns false" do
          expect(object === other).to be false
        end
      end
    end

    context "when comparing with a non-bson integer object" do

      it "returns false" do
        expect(object === []).to be false
      end
    end

    context "when comparing with a non int64 class" do

      it "returns false" do
        expect(object === String).to be false
      end
    end
  end

  describe '#value' do
    let(:obj) { described_class.new(12345) }

    it 'returns value passed to initializer' do
      expect(obj.value).to eq(12345)
    end
  end

  describe '#as_extended_json' do
    context 'canonical mode' do
      it 'returns $numberInt' do
        described_class.new(42).as_extended_json.should == {'$numberInt' => '42'}
      end
    end

    context 'relaxed mode' do
      it 'returns integer' do
        described_class.new(42).as_extended_json(mode: :relaxed).should == 42
      end
    end

    context 'legacy mode' do
      it 'returns integer' do
        described_class.new(42).as_extended_json(mode: :legacy).should be 42
      end
    end
  end
end
