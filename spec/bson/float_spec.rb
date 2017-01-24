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

describe Float do

  describe "#to_bson/#from_bson" do

    let(:type) { 1.chr }
    let(:obj)  { 1.2332 }
    let(:bson) { [ obj ].pack(Float::PACK) }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
  end

  describe "#to_json" do
    let(:obj)  { 1.2332 }

    it "returns the float as a string" do
      expect(obj.to_json).to eq("1.2332")
    end
  end

  describe "#as_extended_json" do
    let(:obj)  { 1.2332 }

    it "returns an extended json representation of the float" do
      expect(obj.as_extended_json).to eq({ Float::EXTENDED_JSON_KEY => obj.to_s })
    end
  end

  describe "#to_extended_json" do
    let(:obj)  { 1.2332 }

    it "returns an extended json representation of the float" do
      expect(obj.to_extended_json).to eq(obj.as_extended_json.to_json)
    end
  end
end
