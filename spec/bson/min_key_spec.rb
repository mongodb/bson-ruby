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

describe BSON::MinKey do

  describe "ExtendedJSON.load" do

    let(:key_set) do
      [ described_class::EXTENDED_JSON_KEY ]
    end

    it "registers the extended JSON keys with the Loader" do
      expect(BSON::ExtendedJSON::MAPPING.keys).to include(key_set)
    end

    it "maps the key set to the MinKey class" do
      expect(BSON::ExtendedJSON::MAPPING[key_set]).to be(described_class)
    end
  end

  describe "#as_json" do

    let(:object) do
      described_class.new
    end

    it "returns the object as a json object" do
      expect(object.as_json).to eq({ described_class::EXTENDED_JSON_KEY => 1 })
    end

    it_behaves_like "a JSON serializable object"
  end

  describe "#to_extended_json" do

    let(:object) do
      described_class.new
    end

    it "returns the object as extended_json" do
      expect(object.to_extended_json).to eq(object.as_extended_json.to_json)
    end
  end

  describe "#as_extended_json" do

    let(:object) do
      described_class.new
    end

    it "returns the object as extended_json" do
      expect(object.as_extended_json).to eq({ described_class::EXTENDED_JSON_KEY => 1})
    end
  end

  describe "#==" do

    context "when the objects are equal" do

      let(:other) { described_class.new }

      it "returns true" do
        expect(subject).to eq(other)
      end
    end

    context "when the other object is not a max_key" do

      it "returns false" do
        expect(subject).to_not eq("test")
      end
    end
  end

  describe "#>" do

    it "always returns false" do
      expect(subject > Integer::MAX_64BIT).to be false
    end
  end

  describe "#<" do

    it "always returns true" do
      expect(subject < Integer::MAX_64BIT).to be true
    end
  end

  describe "#to_bson/#from_bson" do

    let(:type) { 255.chr }
    let(:obj)  { described_class.new }
    let(:bson) { BSON::NO_VALUE }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
  end
end
