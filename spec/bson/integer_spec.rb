# Copyright (C) 2009-2019 MongoDB Inc.
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

  describe '#to_json' do
    it 'returns integer' do
      42.to_json.should == '42'
    end
  end

  describe '#as_extended_json' do
    context 'canonical mode' do
      it 'returns $numberInt' do
        42.as_extended_json.should == {'$numberInt' => '42'}
      end
    end

    context 'relaxed mode' do
      it 'returns integer' do
        42.as_extended_json(mode: :relaxed).should be 42
      end
    end

    context 'legacy mode' do
      it 'returns integer' do
        42.as_extended_json(mode: :legacy).should be 42
      end
    end
  end
end
