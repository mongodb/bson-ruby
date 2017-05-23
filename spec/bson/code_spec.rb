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

describe BSON::Code do

  describe "ExtendedJSON.load" do

    let(:key_set) do
      [ described_class::EXTENDED_JSON_KEY ]
    end

    it "registers the extended JSON keys with the Loader" do
      expect(BSON::ExtendedJSON::MAPPING.keys).to include(key_set)
    end

    it "maps the key set to the Code class" do
      expect(BSON::ExtendedJSON::MAPPING[key_set]).to be(described_class)
    end
  end

  describe "#as_json" do

    let(:object) do
      described_class.new("this.value = 5")
    end

    it "returns a hash with the javascript code" do
      expect(object.as_json).to eq({ "$code" => "this.value = 5" })
    end

    it_behaves_like "a JSON serializable object"
  end

  describe "#to_bson/#from_bson" do

    let(:type) { 13.chr }
    let(:obj)  { described_class.new("this.value = 5") }
    let(:bson) { "#{15.to_bson}this.value = 5#{BSON::NULL_BYTE}" }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
  end
end
