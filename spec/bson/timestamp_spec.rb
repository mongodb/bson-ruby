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

describe BSON::Timestamp do

  describe "#==" do

    let(:timestamp) do
      described_class.new(1, 10)
    end

    context "when the objects are equal" do

      let(:other) { described_class.new(1, 10) }

      it "returns true" do
        expect(timestamp).to eq(other)
      end
    end

    context "when the objects are not equal" do

      let(:other) { described_class.new(1, 15) }

      it "returns false" do
        expect(timestamp).to_not eq(other)
      end
    end

    context "when the other object is not a timestamp" do

      it "returns false" do
        expect(timestamp).to_not eq("test")
      end
    end
  end

  describe "#<=>" do

    let(:timestamp) do
      described_class.new(1, 10)
    end

    context "when the objects are equal" do

      let(:other) { described_class.new(1, 10) }

      it "returns 0" do
        expect(timestamp).to eq(other)
        expect(timestamp < other).to be(false)
        expect(timestamp > other).to be(false)
        expect(timestamp >= other).to be(true)
        expect(timestamp <= other).to be(true)
      end
    end

    context "when the first object is less than the second" do

      let(:other) { described_class.new(1, 15) }

      it "returns -1" do
        expect(timestamp <=> other).to be(-1)
        expect(timestamp < other).to be(true)
        expect(timestamp > other).to be(false)
        expect(timestamp >= other).to be(false)
        expect(timestamp <= other).to be(true)
      end
    end

    context "when the first object is greater than the second" do

      let(:other) { described_class.new(1, 5) }

      it "returns 1" do
        expect(timestamp <=> other).to be(1)
        expect(timestamp < other).to be(false)
        expect(timestamp > other).to be(true)
        expect(timestamp >= other).to be(true)
        expect(timestamp <= other).to be(false)
      end
    end

    context "when the other object is not a timestamp" do

      it "raises an ArgumentError" do
        expect {
          timestamp < 1
        }.to raise_exception(ArgumentError)
      end
    end
  end

  describe "#as_json" do

    let(:object) do
      described_class.new(10, 50)
    end

    it "returns the binary data plus type" do
      expect(object.as_json).to eq({"$timestamp" => { "t" => 10, "i" => 50 } })
    end

    it_behaves_like "a JSON serializable object"
  end

  describe "#to_bson/#from_bson" do

    let(:type) { 17.chr }
    let(:obj)  { described_class.new(1, 10) }
    let(:bson) { [ 10, 1 ].pack(BSON::Int32::PACK * 2) }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
  end
end
