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
require "yaml"

describe BSON::ObjectId do

  describe "#==" do

    context "when data is identical" do

      let(:time) do
        Time.now
      end

      let(:object_id) do
        described_class.from_time(time)
      end

      let(:other_id) do
        described_class.from_time(time)
      end

      it "returns true" do
        expect(object_id).to eq(other_id)
      end
    end

    context "when the data is different" do

      let(:time) do
        Time.now
      end

      let(:object_id) do
        described_class.from_time(time)
      end

      it "returns false" do
        expect(object_id).to_not eq(described_class.new)
      end
    end

    context "when other is not an object id" do

      it "returns false" do
        expect(described_class.new).to_not eq(nil)
      end
    end
  end

  describe "#===" do

    let(:object_id) do
      described_class.new
    end

    context "when comparing with another object id" do

      context "when the data is equal" do

        let(:other) do
          described_class.from_string(object_id.to_s)
        end

        it "returns true" do
          expect(object_id === other).to be true
        end
      end

      context "when the data is not equal" do

        let(:other) do
          described_class.new
        end

        it "returns false" do
          expect(object_id === other).to be false
        end
      end
    end

    context "when comparing to an object id class" do

      it "returns false" do
        expect(object_id === BSON::ObjectId).to be false
      end
    end

    context "when comparing with a string" do

      context "when the data is equal" do

        let(:other) do
          object_id.to_s
        end

        it "returns true" do
          expect(object_id === other).to be true
        end
      end

      context "when the data is not equal" do

        let(:other) do
          described_class.new.to_s
        end

        it "returns false" do
          expect(object_id === other).to be false
        end
      end
    end

    context "when comparing with a non string or object id" do

      it "returns false" do
        expect(object_id === "test").to be false
      end
    end

    context "when comparing with a non object id class" do

      it "returns false" do
        expect(object_id === String).to be false
      end
    end
  end

  describe "#<" do

    let(:object_id) do
      described_class.from_time(Time.utc(2012, 1, 1))
    end

    let(:other_id) do
      described_class.from_time(Time.utc(2012, 1, 30))
    end

    context "when the generation time before the other" do

      it "returns true" do
        expect(object_id < other_id).to be true
      end
    end

    context "when the generation time is after the other" do

      it "returns false" do
        expect(other_id < object_id).to be false
      end
    end
  end

  describe "#>" do

    let(:object_id) do
      described_class.from_time(Time.utc(2012, 1, 1))
    end

    let(:other_id) do
      described_class.from_time(Time.utc(2012, 1, 30))
    end

    context "when the generation time before the other" do

      it "returns false" do
        expect(object_id > other_id).to be false
      end
    end

    context "when the generation time is after the other" do

      it "returns true" do
        expect(other_id > object_id).to be true
      end
    end
  end

  describe "#<=>" do

    let(:object_id) do
      described_class.from_time(Time.utc(2012, 1, 1))
    end

    let(:other_id) do
      described_class.from_time(Time.utc(2012, 1, 30))
    end

    context "when the generation time before the other" do

      it "returns -1" do
        expect(object_id <=> other_id).to eq(-1)
      end
    end

    context "when the generation time is after the other" do

      it "returns false" do
        expect(other_id <=> object_id).to eq(1)
      end
    end
  end

  describe "#as_json" do

    let(:object) do
      described_class.new
    end

    it "returns the object id with $oid key" do
      expect(object.as_json).to eq({ "$oid" => object.to_s })
    end

    it_behaves_like "a JSON serializable object"
  end

  describe "::BSON_TYPE" do

    it "returns 0x07" do
      expect(BSON::ObjectId::BSON_TYPE).to eq(7.chr)
    end
  end

  describe "#bson_type" do

    let(:code) do
      described_class.new
    end

    it "returns 0x0D" do
      expect(code.bson_type).to eq(BSON::ObjectId::BSON_TYPE)
    end
  end

  describe "#eql" do

    context "when data is identical" do

      let(:time) do
        Time.now
      end

      let(:object_id) do
        described_class.from_time(time)
      end

      let(:other_id) do
        described_class.from_time(time)
      end

      it "returns true" do
        expect(object_id).to eql(other_id)
      end
    end

    context "when the data is different" do

      let(:time) do
        Time.now
      end

      let(:object_id) do
        described_class.from_time(time)
      end

      it "returns false" do
        expect(object_id).to_not eql(described_class.new)
      end
    end

    context "when other is not an object id" do

      it "returns false" do
        expect(described_class.new).to_not eql(nil)
      end
    end
  end

  describe ".from_string" do

    context "when the string is valid" do

      let(:string) do
        "4e4d66343b39b68407000001"
      end

      let(:object_id) do
        described_class.from_string(string)
      end

      it "initializes with the string's bytes" do
        expect(object_id.to_s).to eq(string)
      end
    end

    context "when the string is not valid" do

      it "raises an error" do
        expect {
          described_class.from_string("asadsf")
        }.to raise_error(BSON::ObjectId::Invalid)
      end
    end
  end

  describe ".from_time" do

    context "when no unique option is provided" do

      let(:time) do
        Time.at((Time.now.utc - 64800).to_i).utc
      end

      let(:object_id) do
        described_class.from_time(time)
      end

      it "sets the generation time" do
        expect(object_id.generation_time).to eq(time)
      end

      it "does not include process or sequence information" do
        expect(object_id.to_s =~ /\A[0-9a-f]{8}[0]{16}\Z/).to be_truthy
      end
    end

    context "when a unique option is provided" do

      let(:time) do
        Time.at((Time.now.utc - 64800).to_i).utc
      end

      let(:object_id) do
        described_class.from_time(time, :unique => true)
      end

      let(:non_unique) do
        described_class.from_time(time, :unique => true)
      end

      it "creates a new unique object id" do
        expect(object_id).to_not eq(non_unique)
      end
    end
  end

  describe "#generation_time" do

    let(:time) do
      Time.utc(2013, 1, 1)
    end

    let(:object_id) do
      described_class.from_time(time)
    end

    it "returns the generation time" do
      expect(object_id.generation_time).to eq(time)
    end
  end

  describe "#hash" do

    let(:object_id) do
      described_class.new
    end

    it "returns a hash of the raw bytes" do
      expect(object_id.hash).to eq(object_id.to_bson.to_s.hash)
    end
  end

  describe "#initialize" do

    it "does not generate duplicate ids" do
      100000.times do
        expect(BSON::ObjectId.new).to_not eq(BSON::ObjectId.new)
      end
    end
  end

  describe "#clone" do

    context "when the data has not been generated yet" do

      let!(:object_id) do
        described_class.new
      end

      let!(:clone) do
        object_id.clone
      end

      it "generates and copies the data" do
        expect(clone).to eq(object_id)
      end
    end

    context "when the data has been generated" do

      let!(:object_id) do
        described_class.new
      end

      let(:clone) do
        object_id.clone
      end

      before do
        object_id.to_s
      end

      it "copies the data" do
        expect(clone).to eq(object_id)
      end
    end
  end

  describe "#inspect" do

    let(:object_id) do
      described_class.new
    end

    it "returns the inspection with the object id to_s" do
      expect(object_id.inspect).to eq("BSON::ObjectId('#{object_id.to_s}')")
    end

    it "returns a string that evaluates into an equivalent object id" do
      expect(eval object_id.inspect).to eq object_id
    end
  end

  describe ".legal?" do

    context "when the string is too short to be an object id" do

      it "returns false" do
        expect(described_class).to_not be_legal("a" * 23)
      end
    end

    context "when the string contains invalid hex characters" do

      it "returns false" do
        expect(described_class).to_not be_legal("y" + "a" * 23)
      end
    end

    context "when the string is a valid object id" do

      it "returns true" do
        expect(described_class).to be_legal("a" * 24)
      end
    end

    context "when the string contains newlines" do

      it "returns false" do
        expect(described_class).to_not be_legal("\n\n" + "a" * 24 + "\n\n")
      end
    end

    context "when checking against another object id" do

      let(:object_id) do
        described_class.new
      end

      it "returns true" do
        expect(described_class).to be_legal(object_id)
      end
    end
  end

  describe "#marshal_dump" do

    let(:object_id) do
      described_class.new
    end

    let(:dumped) do
      Marshal.dump(object_id)
    end

    it "dumps the raw bytes data" do
      expect(Marshal.load(dumped)).to eq(object_id)
    end
  end

  describe "#marshal_load" do

    context "when the object id was dumped in the old format" do

      let(:legacy) do
        "\x04\bo:\x13BSON::ObjectId\x06:\n" +
          "@data[\x11iUi\x01\xE2i,i\x00i\x00i\x00i\x00i\x00i\x00i\x00i\x00i\x00"
      end

      let(:object_id) do
        Marshal.load(legacy)
      end

      let(:expected) do
        described_class.from_time(Time.utc(2013, 1, 1))
      end

      it "properly loads the object id" do
        expect(object_id).to eq(expected)
      end

      it "removes the bad legacy data" do
        object_id.to_bson
        expect(object_id.instance_variable_get(:@data)).to be_nil
      end
    end
  end

  describe "#to_bson/#from_bson" do

    let(:time) { Time.utc(2013, 1, 1) }
    let(:type) { 7.chr }
    let(:obj)  { described_class.from_time(time) }
    let(:bson) { obj.to_bson.to_s }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
  end

  describe "#to_s" do

    let(:time) do
      Time.utc(2013, 1, 1)
    end

    let(:expected) do
      "50e227000000000000000000"
    end

    let(:object_id) do
      described_class.from_time(time)
    end

    it "returns a hex string representation of the id" do
      expect(object_id.to_s).to eq(expected)
    end

    it "returns the string in UTF-8" do
      expect(object_id.to_s.encoding).to eq(Encoding.find(BSON::UTF8))
    end

    it "converts to a readable yaml string" do
      expect(YAML.dump(object_id.to_s)).to include(expected)
    end
  end

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(BSON::ObjectId::BSON_TYPE, 'field')
    end

    it "registers the type" do
      expect(registered).to eq(described_class)
    end
  end

  context "when the ids are used as keys" do

    let(:object_id) do
      described_class.new
    end

    let(:hash) do
      { object_id => 1 }
    end

    it "raises an exception on serialization" do
      expect {
        hash.to_bson
      }.to raise_error(BSON::InvalidKey)
    end
  end
end
