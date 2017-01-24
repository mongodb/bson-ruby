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

describe Symbol do

  describe "ExtendedJSON.load" do

    let(:key_set) do
      [ described_class::EXTENDED_JSON_KEY ]
    end

    it "registers the extended JSON keys with the Loader" do
      expect(BSON::ExtendedJSON::MAPPING.keys).to include(key_set)
    end

    it "maps the key set to the Symbol class" do
      expect(BSON::ExtendedJSON::MAPPING[key_set]).to be(described_class)
    end
  end

  describe "#bson_type" do

    it "returns the type for a string" do
      expect(:type.bson_type).to eq("type".bson_type)
    end
  end

  describe "#to_bson/#from_bson" do

    let(:type) { 2.chr }
    let(:obj)  { :test }
    let(:bson) { "#{5.to_bson.to_s}test#{BSON::NULL_BYTE}" }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
  end

  describe "#as_extended_json" do

    let(:object) do
      :test
    end

    it "returns the symbol as Extended JSON" do
      expect(object.as_extended_json).to eq({ described_class::EXTENDED_JSON_KEY => object.to_s })
    end
  end

  describe "#to_json" do

    let(:object) do
      :test
    end

    it "returns the symbol object as a string" do
      expect(object.to_json).to eq(object.to_s.to_json)
    end
  end

  describe "#to_extended_json" do

    let(:object) do
      :test
    end

    it "returns the symbol object as extended_json" do
      expect(object.to_extended_json).to eq(object.as_extended_json.to_json)
    end
  end

  describe "#to_bson_key" do

    let(:symbol) { :test }
    let(:encoded) { symbol.to_s }

    it "returns the encoded string" do
      expect(symbol.to_bson_key).to eq(encoded)
    end
  end

  describe "#to_bson_key" do

    context "when validating keys" do

      let(:symbol) do
        :'$testing.testing'
      end

      it "raises an exception" do
        expect {
          symbol.to_bson_key(true)
        }.to raise_error(BSON::String::IllegalKey)
      end
    end

    context "when not validating keys" do

      let(:symbol) do
        :'$testing.testing'
      end

      it "allows invalid keys" do
        expect(symbol.to_bson_key).to eq(symbol.to_s)
      end
    end
  end
end
