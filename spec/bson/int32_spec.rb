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
end
