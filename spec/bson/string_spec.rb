# encoding: utf-8

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

describe String do

  describe "#to_bson/#from_bson" do

    let(:type) { 2.chr }
    let(:obj) { "test" }
    let(:bson) { "#{5.to_bson.to_s}test#{BSON::NULL_BYTE}" }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
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

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(String::BSON_TYPE, 'field')
    end

    it "registers the type" do
      expect(registered).to eq(String)
    end
  end

  describe "#to_bson_key" do

    let(:string) { "test" }
    let(:encoded) { string.to_s }

    it "returns the encoded string" do
      expect(string.to_bson_key).to eq(encoded)
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

  describe "#to_bson_key" do

    context "when validating keys" do

      context "when validating globally" do

        before do
          BSON::Config.validating_keys = true
        end

        after do
          BSON::Config.validating_keys = false
        end

        let(:validated) do
          string.to_bson_key
        end

        it_behaves_like "a validated BSON key"
      end

      context "when validating locally" do

        let(:validated) do
          string.to_bson_key(true)
        end

        it_behaves_like "a validated BSON key"
      end
    end

    context "when allowing invalid keys" do

      let(:string) do
        "$testing.testing"
      end

      it "allows invalid keys" do
        expect(string.to_bson_key).to eq(string)
      end
    end
  end
end
