# Copyright (C) 2009-2013 MongoDB Inc.
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

  unless RUBY_VERSION < "1.9"
    it "returns the string with binary encoding" do
      expect(encoded.encoding).to eq(binary_encoding)
    end
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

  let(:previous_content) do
    'previous_content'.force_encoding(BSON::BINARY)
  end

  it "serializes to bson" do
    expect(obj.to_bson).to eq(bson)
  end

  it "serializes to bson by appending" do
    expect(obj.to_bson(previous_content)).to eq(previous_content << bson)
  end
end

shared_examples_for "a deserializable bson element" do

  let(:io) do
    StringIO.new(bson)
  end

  it "deserializes from bson" do
    expect(described_class.from_bson(io)).to eq(obj)
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
      BSON::Document.from_bson(StringIO.new(document.to_bson))
    ).to eq(document)
  end
end

shared_examples_for "a class which converts to Time" do

  it "shares BSON type with Time" do
    expect(described_class.new.bson_type).to eq(Time::BSON_TYPE)
  end
end
