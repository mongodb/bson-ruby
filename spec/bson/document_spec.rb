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

describe BSON::Document do

  let(:keys) { %w(blue green red pink orange) }
  let(:vals) { %w(000099 009900 aa0000 cc0066 cc6633) }
  let(:doc)  { described_class.new }
  let(:hash) do
    {}
  end
  let(:enum_class) do
    Enumerator
  end

  before do
    keys.each_with_index do |key, index|
      hash[key] = vals[index]
      doc[key] = vals[index]
    end
  end

  describe "#keys" do

    it "retains the insertion order" do
      expect(doc.keys).to eq(keys)
    end
  end

  describe "#values" do

    it "retains the insertion order" do
      expect(doc.values).to eq(vals)
    end
  end

  describe "#[]" do

    let(:document) do
      described_class["key", "value", "key2", "value"]
    end

    context "when provided string keys" do

      it "returns the value" do
        expect(document["key"]).to eq("value")
      end
    end

    context "when provided symbol keys" do

      it "returns the value" do
        expect(document[:key]).to eq("value")
      end
    end
  end

  describe "#[]=" do

    let(:key) { "purple" }
    let(:val) { "5422a8" }

    before do
      doc[key] = val
    end

    it "updates the length" do
      expect(doc.length).to eq(keys.length + 1)
    end

    it "adds the key to the end" do
      expect(doc.keys.last).to eq(key)
    end

    it "adds the value to the end" do
      expect(doc.values.last).to eq(val)
    end

    it "sets the value" do
      expect(doc[key]).to eq(val)
    end
  end

  describe "#delete" do

    let(:key) { "white" }
    let(:val) { "ffffff" }
    let(:bad_key) { "black" }

    before do
      doc[key] = val
    end

    let!(:deleted) { doc.delete(key) }

    it "returns the deleted value" do
      expect(deleted).to eq(val)
    end

    it "removes the key from the list" do
      expect(doc.keys.length).to eq(keys.length)
    end

    it "matches the keys length to the document length" do
      expect(doc.length).to eq(doc.keys.length)
    end

    context "when removind a bad key" do

      it "returns nil" do
        expect(doc.delete(bad_key)).to be_nil
      end
    end
  end

  describe "#to_hash" do

    it "returns the document" do
      expect(doc.to_hash).to eq(doc)
    end
  end

  describe "#to_a" do

    it "returns the key/value pairs as an array" do
      expect(doc.to_a).to eq(keys.zip(vals))
    end
  end

  [ :has_key?, :key?, :include?, :member? ].each do |method|

    describe "##{method}" do

      context "when the key exists" do

        it "returns true" do
          expect(doc.send(method, "blue")).to be_true
        end
      end

      context "when the key does not exist" do

        it "returns false" do
          expect(doc.send(method, "indigo")).to be_false
        end
      end
    end
  end

  [ :has_value?, :value? ].each do |method|

    describe "##{method}" do

      context "when the value exists" do

        it "returns true" do
          expect(doc.send(method, "000099")).to be_true
        end
      end

      context "when the value does not exist" do

        it "returns false" do
          expect(doc.send(method, "ABCABC")).to be_false
        end
      end
    end
  end

  describe "#each_key" do

    let(:iter_keys) {[]}

    context "when passed a block" do

      let!(:enum) do
        doc.each_key{ |k| iter_keys << k }
      end

      it "returns the document" do
        expect(enum).to equal(doc)
      end

      it "iterates over each of the keys" do
        expect(iter_keys).to eq(keys)
      end
    end

    context "when not passed a block" do

      let!(:enum) do
        doc.each_key
      end

      it "returns an enumerator" do
        expect(enum).to be_a(enum_class)
      end
    end
  end

  describe "#each_value" do

    let(:iter_vals) {[]}

    context "when passed a block" do

      let!(:enum) do
        doc.each_value{ |v| iter_vals << v }
      end

      it "returns the document" do
        expect(enum).to equal(doc)
      end

      it "iterates over each of the vals" do
        expect(iter_vals).to eq(vals)
      end
    end

    context "when not passed a block" do

      let!(:enum) do
        doc.each_value
      end

      it "returns an enumerator" do
        expect(enum).to be_a(enum_class)
      end
    end
  end

  [ :each, :each_pair ].each do |method|

    describe "##{method}" do

      let(:iter_keys) {[]}
      let(:iter_vals) {[]}

      context "when passed a block" do

        let!(:enum) do
          doc.send(method) do |k, v|
            iter_keys << k
            iter_vals << v
          end
        end

        it "returns the document" do
          expect(enum).to equal(doc)
        end

        it "iterates over each of the keys" do
          expect(iter_keys).to eq(keys)
        end

        it "iterates over each of the vals" do
          expect(iter_vals).to eq(vals)
        end
      end

      context "when not passed a block" do

        let!(:enum) do
          doc.send(method)
        end

        it "returns an enumerator" do
          expect(enum).to be_a(enum_class)
        end
      end

      context "when the document has been serialized" do

        let(:deserialized) do
          YAML.load(YAML.dump(doc))
        end

        let!(:enum) do
          deserialized.send(method) do |k, v|
            iter_keys << k
            iter_vals << v
          end
        end

        it "iterates over each of the keys" do
          expect(iter_keys).to eq(keys)
        end

        it "iterates over each of the vals" do
          expect(iter_vals).to eq(vals)
        end
      end
    end
  end

  describe "#each_with_index" do

    it "iterates over the document passing an index" do
      doc.each_with_index do |pair, index|
        expect(pair).to eq([ keys[index], vals[index] ])
      end
    end
  end

  describe "#find_all" do

    it "iterates in the correct order" do
      expect(doc.find_all{ true }.map(&:first)).to eq(keys)
    end
  end

  describe "#select" do

    it "iterates in the correct order" do
      expect(doc.select{ true }.map(&:first)).to eq(keys)
    end
  end

  [ :delete_if, :reject! ].each do |method|

    describe "##{method}" do

      let(:copy) { doc.dup }

      before do
        copy.delete("pink")
      end

      let!(:deleted) do
        doc.send(method){ |k, _| k == "pink" }
      end

      it "deletes elements for which the block is true" do
        expect(deleted).to eq(copy)
      end

      it "deletes the matching keys from the document" do
        expect(doc.keys).to_not include("pink")
      end

      it "returns the same document" do
        expect(deleted).to equal(doc)
      end
    end
  end

  describe "#reject" do

    let(:copy) { doc.dup }

    before do
      copy.delete("pink")
    end

    let!(:deleted) do
      doc.reject{ |k, _| k == "pink" }
    end

    it "deletes elements for which the block is true" do
      expect(deleted).to eq(copy)
    end

    it "deletes the matching keys from the new document" do
      expect(deleted.keys).to_not include("pink")
    end

    it "returns a new document" do
      expect(deleted).to_not equal(doc)
    end
  end

  describe "#clear" do

    before do
      doc.clear
    end

    it "clears out the keys" do
      expect(doc.keys).to be_empty
    end
  end

  describe "#merge" do

    let(:other) { described_class.new }

    context "when passed no block" do

      before do
        other["purple"] = "800080"
        other["violet"] = "ee82ee"
      end

      let!(:merged) do
        doc.merge(other)
      end

      it "merges the keys" do
        expect(merged.keys).to eq(keys + [ "purple", "violet" ])
      end

      it "adds to the length" do
        expect(merged.length).to eq(doc.length + other.length)
      end

      it "returns a new document" do
        expect(merged).to_not equal(doc)
      end
    end

    context "when passed a block" do

      before do
        other[:a] = 0
        other[:b] = 0
      end

      let(:merged) do
        other.merge(:b => 2, :c => 7) do |key, old_val, new_val|
          new_val + 1
        end
      end

      it "executes the block on each merged element" do
        expect(merged[:a]).to eq(0)
        expect(merged[:b]).to eq(3)
        expect(merged[:c]).to eq(7)
      end
    end
  end

  describe "#merge!" do

    let(:other) { described_class.new }

    context "when passed no block" do

      before do
        other["purple"] = "800080"
        other["violet"] = "ee82ee"
      end

      let(:merged) do
        doc.merge!(other)
      end

      it "merges the keys" do
        expect(merged.keys).to eq(keys + [ "purple", "violet" ])
      end

      it "adds to the length" do
        expect(merged.length).to eq(doc.length)
      end

      it "returns the same document" do
        expect(merged).to equal(doc)
      end
    end

    context "when passed a block" do

      before do
        other[:a] = 0
        other[:b] = 0
      end

      let!(:merged) do
        other.merge!(:b => 2, :c => 7) do |key, old_val, new_val|
          new_val + 1
        end
      end

      it "executes the block on each merged element" do
        expect(other[:a]).to eq(0)
        expect(other[:b]).to eq(3)
        expect(other[:c]).to eq(7)
      end
    end
  end

  describe "#shift" do

    let(:pair) do
      doc.shift
    end

    it "returns the first pair in the document" do
      expect(pair).to eq([ keys.first, vals.first ])
    end

    it "removes the pair from the document" do
      expect(doc.keys).to_not eq(pair.first)
    end
  end

  describe "#inspect" do

    it "includes the hash inspect" do
      expect(doc.inspect).to include(hash.inspect)
    end
  end

  describe "#initialize" do

    context "when provided for splat args" do

      context "when an even number of args" do

        let(:alternate) do
          described_class[1, 2, 3, 4]
        end

        it "treats the arguments are an array" do
          expect(alternate.keys).to eq([ 1, 3 ])
        end

        it "instantiates a document" do
          expect(alternate).to be_a(BSON::Document)
        end
      end

      context "when an odd number of arguments" do

        it "raises an argument error" do
          expect {
            described_class[1, 2, 3]
          }.to raise_error(ArgumentError)
        end
      end
    end

    context "when provided an array" do

      let(:alternate) do
        described_class[[[ 1, 2 ], [ 3, 4 ], [ "missing" ]]]
      end

      it "sets the keys" do
        expect(alternate.keys).to eq([ 1, 3, "missing" ])
      end

      it "sets the values" do
        expect(alternate.values).to eq([ 2, 4, nil ])
      end
    end

    context "when provided hashes" do

      let(:alternate) do
        described_class[1 => 2, 3 => 4]
      end

      it "sets the keys" do
        expect(alternate.keys).to eq([ 1, 3 ])
      end

      it "sets the values" do
        expect(alternate.values).to eq([ 2, 4 ])
      end
    end
  end

  describe "#replace" do

    let(:other) do
      described_class[:black, "000000", :white, "000000"]
    end

    let!(:original) { doc.replace(other) }

    it "replaces the keys" do
      expect(doc.keys).to eq(other.keys)
    end

    it "returns the document" do
      expect(original).to eq(doc)
    end
  end

  describe "#update" do

    let(:updated) { described_class.new }

    before do
      updated.update(:name => "Bob")
    end

    it "updates the keys" do
      expect(updated.keys).to eq([ :name ])
    end

    it "updates the values" do
      expect(updated.values).to eq([ "Bob" ])
    end
  end

  describe "#invert" do

    let(:expected) do
      described_class[vals.zip(keys)]
    end

    it "inverts the hash in inverse order" do
      expect(doc.invert).to eq(expected)
    end

    it "inverts the keys" do
      expect(vals.zip(keys)).to eq(doc.invert.to_a)
    end
  end

  describe "#to_bson/#from_bson" do

    let(:type) { 3.chr }

    it_behaves_like "a bson element"

    context "when the hash has symbol keys" do

      let(:obj) do
        described_class[:ismaster, 1].freeze
      end

      let(:bson) do
        "#{19.to_bson}#{BSON::Int32::BSON_TYPE}ismaster#{BSON::NULL_BYTE}" +
        "#{1.to_bson}#{BSON::NULL_BYTE}"
      end

      it "properly serializes the symbol" do
        expect(obj.to_bson).to eq(bson)
      end
    end

    context "when the hash is a single level" do

      let(:obj) do
        described_class["key","value"]
      end

      let(:bson) do
        "#{20.to_bson}#{String::BSON_TYPE}key#{BSON::NULL_BYTE}" +
        "#{6.to_bson}value#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}"
      end

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the hash is embedded" do

      let(:obj) do
        described_class["field", BSON::Document["key", "value"]]
      end

      let(:bson) do
        "#{32.to_bson}#{Hash::BSON_TYPE}field#{BSON::NULL_BYTE}" +
        "#{20.to_bson}#{String::BSON_TYPE}key#{BSON::NULL_BYTE}" +
        "#{6.to_bson}value#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}"
      end

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"

      let(:raw) do
        StringIO.new(bson)
      end

      it "returns an instance of a BSON::Document" do
        expect(described_class.from_bson(raw)).to be_a(BSON::Document)
      end
    end
  end

  context "when encoding and decoding" do

    context "when the keys are utf-8" do

      let(:document) do
        described_class["gültig", "type"]
      end

      it_behaves_like "a document able to handle utf-8"
    end

    context "when the values are utf-8" do

      let(:document) do
        described_class["type", "gültig"]
      end

      it_behaves_like "a document able to handle utf-8"
    end

    context "when both the keys and values are utf-8" do

      let(:document) do
        described_class["gültig", "gültig"]
      end

      it_behaves_like "a document able to handle utf-8"
    end

    context "when the regexps are utf-8" do

      let(:document) do
        described_class["type", /^gültig/]
      end

      it_behaves_like "a document able to handle utf-8"
    end

    context "when the symbols are utf-8" do

      let(:document) do
        described_class["type", "gültig".to_sym]
      end

      it_behaves_like "a document able to handle utf-8"
    end

    context "when utf-8 string values are in an array" do

      let(:document) do
        described_class["type", ["gültig"]]
      end

      it_behaves_like "a document able to handle utf-8"
    end

    context "when utf-8 code values are present" do

      let(:document) do
        described_class["code", BSON::Code.new("// gültig")]
      end

      it_behaves_like "a document able to handle utf-8"
    end

    context "when utf-8 code with scope values are present" do

      let(:document) do
        described_class["code", BSON::CodeWithScope.new("// gültig", {})]
      end

      it_behaves_like "a document able to handle utf-8"
    end

    context "when non utf-8 values exist" do

      let(:string) { "gültig" }
      let(:document) do
        described_class["type", string.encode("iso-8859-1")]
      end

      it "encodes and decodes the document properly" do
        expect(
          BSON::Document.from_bson(StringIO.new(document.to_bson))
        ).to eq({ "type" => string })
      end
    end

    context "when binary strings with utf-8 values exist" do

      let(:string) { "europäischen" }
      let(:document) do
        described_class["type", string.encode("binary", "binary")]
      end

      it "encodes and decodes the document properly" do
        expect(
          BSON::Document.from_bson(StringIO.new(document.to_bson))
        ).to eq({ "type" => string })
      end
    end
  end
end
