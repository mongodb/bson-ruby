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

shared_examples_for "a binary encoded string" do

  let(:binary_encoding) do
    Encoding.find(BSON::BINARY)
  end

  it "returns the string with binary encoding" do
    expect(encoded.encoding).to eq(binary_encoding)
  end
end

shared_examples_for "a bson element" do

  let(:element) do
    defined?(obj) ? obj : described_class.new
  end

  it "has the correct single byte BSON type" do
    expect(element.bson_type).to eq(type)
  end
end

shared_examples_for "a serializable bson element" do

  it "serializes to bson" do
    expect(obj.to_bson.to_s).to eq(bson)
  end
end

shared_examples_for "a deserializable bson element" do

  let(:io) do
    BSON::ByteBuffer.new(bson)
  end

  let(:result) do
    (defined?(klass) ? klass : described_class).from_bson(io)
  end

  it "deserializes from bson" do
    expect(result).to eq(obj)
  end
end

shared_examples_for "a JSON serializable object" do

  it "serializes the JSON from #as_json" do
    expect(object.to_json).to eq(object.as_json.to_json)
  end
end

shared_examples_for "immutable when frozen" do |block|

  context "when the document is frozen" do

    before do
      doc.freeze
    end

    it "raises a runtime error" do
      expect {
        block.call(doc)
      }.to raise_error(RuntimeError)
    end
  end
end

shared_examples_for "a document able to handle utf-8" do

  it "serializes and deserializes properly" do
    expect(
      BSON::Document.from_bson(BSON::ByteBuffer.new(document.to_bson.to_s))
    ).to eq(document)
  end
end

shared_examples_for "a class which converts to Time" do

  it "shares BSON type with Time" do
    expect(described_class.new.bson_type).to eq(Time::BSON_TYPE)
  end
end

shared_examples_for "a validated BSON key" do

  context "when the string is valid" do

    context "when the string has no invalid characters" do

      let(:string) do
        "testing"
      end

      it "returns the key" do
        expect(validated).to eq(string)
      end
    end

    context "when the string contains a $" do

      let(:string) do
        "te$ting"
      end

      it "returns the key" do
        expect(validated).to eq(string)
      end
    end
  end

  context "when the string is invalid" do

    context "when the string starts with $" do

      let(:string) do
        "$testing"
      end

      it "raises an exception" do
        expect {
          validated
        }.to raise_error(BSON::String::IllegalKey)
      end
    end

    context "when the string contains a ." do

      let(:string) do
        "testing.testing"
      end

      it "raises an exception" do
        expect {
          validated
        }.to raise_error(BSON::String::IllegalKey)
      end
    end
  end
end
