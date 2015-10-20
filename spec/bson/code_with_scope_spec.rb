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

describe BSON::CodeWithScope do

  describe "#==" do

    let(:object) do
      BSON::CodeWithScope.new("this.value = val", "test")
    end

    context "when the objects are equal" do
      let(:other) { described_class.new("this.value = val", "test") }

      it "returns true" do
        expect(object).to eq(other)
      end
    end

    context "when the other object is not equal" do
      let(:other) { described_class.new("this.value = otherVal", "test") }

      it "returns false" do
        expect(object).to_not eq(other)
      end
    end
  end

  describe "#as_json" do

    let(:object) do
      described_class.new("this.value = val", :val => "test")
    end

    it "returns the binary data plus type" do
      expect(object.as_json).to eq(
        { "$code" => "this.value = val", "$scope" => { :val => "test" }}
      )
    end

    it_behaves_like "a JSON serializable object"
  end

  describe "#to_bson" do

    let(:type) { 15.chr }
    let(:code) { "this.value == name" }
    let(:scope) do
      { :name => "test" }
    end
    let(:obj) { described_class.new(code, scope) }
    let(:bson) do
      "#{47.to_bson.to_s}#{(code.length + 1).to_bson.to_s}#{code}#{BSON::NULL_BYTE}" +
      "#{scope.to_bson.to_s}"
    end

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
  end

  describe "#from_bson" do

    let(:type) { 15.chr }
    let(:code) { "this.value == name" }
    let(:scope) do
      { "name" => "test" }
    end
    let(:obj) { described_class.new(code, scope) }
    let(:bson) { BSON::ByteBuffer.new(obj.to_bson.to_s) }
    let!(:deserialized) { described_class.from_bson(bson) }

    it "deserializes the javascript" do
      expect(deserialized.javascript).to eq(code)
    end

    it "deserializes the scope" do
      expect(deserialized.scope).to eq(scope)
    end
  end
end
