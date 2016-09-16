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

describe BSON::Int32 do

  describe "#intiialize" do

    let(:obj) { described_class.new(integer) }

    context "when the integer is 32-bit" do

      let(:integer) { Integer::MAX_32BIT }

      it "wraps the integer" do
        expect(obj.instance_variable_get(:@integer)).to be(integer)
      end
    end

    context "when the integer is too large" do

      let(:integer) { Integer::MAX_32BIT + 1 }

      it "raises an out of range error" do
        expect {
          obj
        }.to raise_error(RangeError)
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
    let(:encoded) { (Integer::MAX_32BIT - 1).to_s }

    it "returns the key as a string" do
      expect(obj.to_bson_key).to eq(encoded)
    end
  end
end
