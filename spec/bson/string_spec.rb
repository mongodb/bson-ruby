# encoding: utf-8

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

require "spec_helper"

describe String do

  describe "#to_bson/#from_bson" do

    let(:type) { 2.chr }
    let(:obj) { "test" }
    let(:bson) { "#{5.to_bson}test#{BSON::NULL_BYTE}" }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
  end

  describe "#to_bson_cstring" do

    context "when the string is valid" do

      let(:string) do
        "test"
      end

      let(:encoded) do
        string.to_bson_cstring
      end

      let(:previous_content) do
        'previous_content'.force_encoding(BSON::BINARY)
      end

      it "returns the encoded string" do
        expect(encoded).to eq("test#{BSON::NULL_BYTE}")
      end

      it_behaves_like "a binary encoded string"

      it "appends to optional previous content" do
        expect(string.to_bson_cstring(previous_content)).to eq(previous_content << encoded)
      end
    end

    context "when the string contains a null byte" do

      let(:string) do
        "test#{BSON::NULL_BYTE}ing"
      end

      it "raises an error" do
        expect {
          string.to_bson_cstring
        }.to raise_error(ArgumentError)
      end
    end

    context "when the string contains utf-8 characters" do

      let(:string) do
        "Straße"
      end

      let(:encoded) do
        string.to_bson_cstring
      end

      let(:char) do
        "ß".chr.force_encoding(BSON::BINARY)
      end

      it "returns the encoded string" do
        expect(encoded).to eq("Stra#{char}e#{BSON::NULL_BYTE}")
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the string is encoded in non utf-8" do

      let(:string) do
        "Straße".encode("iso-8859-1")
      end

      let(:encoded) do
        string.to_bson_cstring
      end

      let(:char) do
        "ß".chr.force_encoding(BSON::BINARY)
      end

      it "returns the encoded string" do
        expect(encoded).to eq("Stra#{char}e#{BSON::NULL_BYTE}")
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the string contains non utf-8 characters" do

      let(:string) do
        255.chr
      end

      it "raises an error" do
        expect {
          string.to_bson_cstring
        }.to raise_error(EncodingError)
      end
    end
  end

  describe "#to_bson_object_id" do

    context "when the string has 12 characters" do

      let(:string) do
        "123456789012"
      end

      let(:converted) do
        string.to_bson_object_id
      end

      it "returns the array as a string" do
        expect(converted).to eq(string)
      end
    end

    context "when the array does not have 12 elements" do

      it "raises an exception" do
        expect {
          "test".to_bson_object_id
        }.to raise_error(BSON::ObjectId::Invalid)
      end
    end
  end

  describe "#to_bson_string" do

    context "when the string is valid" do

      let(:string) do
        "test"
      end

      let(:encoded) do
        string.to_bson_string
      end

      let(:previous_content) do
        'previous_content'.force_encoding(BSON::BINARY)
      end

      it "returns the string" do
        expect(encoded).to eq(string)
      end

      it_behaves_like "a binary encoded string"

      it "appends to optional previous content" do
        expect(string.to_bson_string(previous_content)).to eq(previous_content << encoded)
      end

    end

    context "when the string contains a null byte" do

      let(:string) do
        "test#{BSON::NULL_BYTE}ing"
      end

      let(:encoded) do
        string.to_bson_string
      end

      it "retains the null byte" do
        expect(encoded).to eq(string)
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the string contains utf-8 characters" do

      let(:string) do
        "Straße"
      end

      let(:encoded) do
        string.to_bson_string
      end

      let(:char) do
        "ß".chr.force_encoding(BSON::BINARY)
      end

      it "returns the encoded string" do
        expect(encoded).to eq("Stra#{char}e")
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the string is encoded in non utf-8" do

      let(:string) do
        "Straße".encode("iso-8859-1")
      end

      let(:encoded) do
        string.to_bson_string
      end

      let(:char) do
        "ß".chr.force_encoding(BSON::BINARY)
      end

      it "returns the encoded string" do
        expect(encoded).to eq("Stra#{char}e")
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the string contains non utf-8 characters" do

      let(:string) do
        255.chr
      end

      it "raises an error" do
        expect {
          string.to_bson_string
        }.to raise_error(EncodingError)
      end
    end
  end

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(String::BSON_TYPE)
    end

    it "registers the type" do
      expect(registered).to eq(String)
    end
  end

  describe "#to_bson_key" do

    let(:string) { "test" }
    let(:encoded) { string.to_s + BSON::NULL_BYTE }
    let(:previous_content) { 'previous_content'.force_encoding(BSON::BINARY) }

    it "returns the encoded string" do
      expect(string.to_bson_key).to eq(encoded)
    end

    it "appends to optional previous content" do
      expect(string.to_bson_key(previous_content)).to eq(previous_content << encoded)
    end
  end

  describe "#to_hex_string" do

    let(:string) do
      "testing123"
    end

    it "converts the string to hex" do
      expect(string.to_hex_string).to eq("74657374696e67313233")
    end
  end
end
