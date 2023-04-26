# rubocop:todo all
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

describe Integer do

  describe "#to_bson" do

    context "when the integer is 32 bit" do

      let(:type) { 16.chr }
      let(:obj)  { Integer::MAX_32BIT - 1 }
      let(:bson) { [ obj ].pack(BSON::Int32::PACK) }

      it_behaves_like "a serializable bson element"
    end

    context "when the integer is 64 bit" do

      let(:type) { 18.chr }
      let(:obj)  { Integer::MAX_64BIT - 1 }
      let(:bson) { [ obj ].pack(BSON::Int64::PACK) }

      it_behaves_like "a serializable bson element"
    end

    context "when the integer is too large" do

      let(:integer) { Integer::MAX_64BIT + 1 }

      it "raises an out of range error" do
        expect {
          integer.to_bson
        }.to raise_error(RangeError)
      end
    end

    context "when the intger is too small" do

      let(:integer) { Integer::MIN_64BIT - 1 }

      it "raises an out of range error" do
        expect {
          integer.to_bson
        }.to raise_error(RangeError)
      end
    end
  end

  describe "#to_bson_key" do

    let(:obj)  { Integer::MAX_32BIT - 1 }
    let(:encoded) { obj }

    it "returns the key as an integer" do
      expect(obj.to_bson_key).to eq(encoded)
    end
  end

  describe '#as_json' do
    it 'returns an integer string' do
      expect(42.to_json).to eq '42'
    end
  end

  describe '#as_extended_json' do

    context 'when 32-bit representable' do
      let(:object) { 42 }

      context 'canonical mode' do
        it 'returns $numberInt when small' do
          expect(object.as_extended_json).to eq({ '$numberInt' => '42' })
        end
      end

      context 'relaxed mode' do
        it 'returns integer' do
          expect(object.as_extended_json(mode: :relaxed)).to eq 42
        end
      end

      context 'legacy mode' do
        it 'returns integer' do
          expect(object.as_extended_json(mode: :legacy)).to eq 42
        end
      end

      it_behaves_like "an Extended JSON serializable object"
    end

    context 'when not 32-bit representable' do
      let(:object) { 18014398241046527 }

      context 'canonical mode' do
        it 'returns $numberInt when small' do
          expect(object.as_extended_json).to eq({ '$numberLong' => '18014398241046527' })
        end
      end

      context 'relaxed mode' do
        it 'returns integer' do
          expect(object.as_extended_json(mode: :relaxed)).to eq 18014398241046527
        end
      end

      context 'legacy mode' do
        it 'returns integer' do
          expect(object.as_extended_json(mode: :legacy)).to eq 18014398241046527
        end
      end

      it_behaves_like "an Extended JSON serializable object"
    end
  end
end
