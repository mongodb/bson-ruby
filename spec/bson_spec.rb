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

describe BSON do

  describe ".ObjectId" do

    context 'when given a string' do
      let(:string) { "4e4d66343b39b68407000001" }

      it "returns an BSON::ObjectId from given string" do
        expect(described_class::ObjectId(string)).to be_a BSON::ObjectId
        expect(described_class::ObjectId(string)).to eq BSON::ObjectId.from_string(string)
      end
    end

    context 'when given an object id' do
      let(:object_id) do
        BSON::ObjectId.new
      end

      it 'returns the same object' do
        expect(described_class::ObjectId(object_id)).to be(object_id)
      end
    end
  end

  describe "::BINARY" do

    it "returns BINARY" do
      expect(BSON::BINARY).to eq("BINARY")
    end
  end

  describe "::NO_VAUE" do

    it "returns an empty string" do
      expect(BSON::NO_VALUE).to be_empty
    end
  end

  describe "::NULL_BYTE" do

    it "returns the char 0x00" do
      expect(BSON::NULL_BYTE).to eq(0.chr)
    end
  end

  describe "::UTF8" do

    it "returns UTF-8" do
      expect(BSON::UTF8).to eq("UTF-8")
    end
  end
end
