# encoding: utf-8

# Copyright (C) 2009-2019 MongoDB Inc.
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

  describe "#fetch" do

    let(:document) do
      described_class["key", "value", "key2", "value"]
    end

    context "when provided string keys" do

      it "returns the value" do
        expect(document.fetch("key")).to eq("value")
      end
    end

    context "when provided symbol keys" do

      it "returns the value" do
        expect(document.fetch(:key)).to eq("value")
      end
    end

    context "when key does not exist" do

      it "raises KeyError" do
        expect do
          document.fetch(:non_existent_key)
        end.to raise_exception(KeyError)
      end

      context "and default value is provided" do

        it "returns default value" do
          expect(document.fetch(:non_existent_key, false)).to eq(false)
        end
      end

      context "and block is passed" do

        it "returns result of the block" do
          expect(document.fetch(:non_existent_key, &:to_s))
            .to eq("non_existent_key")
        end
      end
    end

    context "when key exists" do

      context "and default value is provided" do

        it "returns the value" do
          expect(document.fetch(:key, "other")).to eq("value")
        end
      end

      context "and block is passed" do

        it "returns the value" do
          expect(document.fetch(:key, &:to_s)).to eq("value")
        end
      end
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

    context "when key does not exist" do

      it "returns nil" do
        expect(document[:non_existent_key]).to be nil
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

    context 'when value is a hash' do
      let(:val) do
        {'foo' => {'bar' => 'baz'}}
      end

      it 'converts value to indifferent access' do
        expect(doc[key][:foo][:bar]).to eq('baz')
      end
    end

    context 'when value is an array with hash element' do
      let(:val) do
        [42, {'foo' => {'bar' => 'baz'}}]
      end

      it 'converts hash element to indifferent access' do
        expect(doc[key][1][:foo][:bar]).to eq('baz')
      end
    end
  end

  if described_class.instance_methods.include?(:dig)
    describe "#dig" do
      let(:document) do
        described_class.new("key1" => { :key2 => "value" })
      end

      context "when provided string keys" do

        it "returns the value" do
          expect(document.dig("key1", "key2")).to eq("value")
        end
      end

      context "when provided symbol keys" do

        it "returns the value" do
          expect(document.dig(:key1, :key2)).to eq("value")
        end
      end
    end
  end

  if described_class.instance_methods.include?(:slice)
    describe "#slice" do
      let(:document) do
        described_class.new("key1" => "value1", key2: "value2")
      end

      context "when provided string keys" do

        it "returns the partial document" do
          expect(document.slice("key1")).to contain_exactly(['key1', 'value1'])
        end
      end

      context "when provided symbol keys" do

        it "returns the partial document" do
          expect(document.slice(:key1)).to contain_exactly(['key1', 'value1'])
        end
      end
    end
  end

  describe "#delete" do

    shared_examples_for "a document with deletable pairs" do

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

      context "when removing a bad key" do

        it "returns nil" do
          expect(doc.delete(bad_key)).to be_nil
        end

        context "when a block is provided" do

          it "returns the result of the block" do
            expect(doc.delete(bad_key) { |k| "golden key" }).to eq("golden key")
          end
        end
      end
    end

    context "when keys are strings" do

      let(:key) { "white" }
      let(:val) { "ffffff" }
      let(:bad_key) { "black" }

      before do
        doc[key] = val
      end

      it_behaves_like "a document with deletable pairs"
    end

    context "when keys are symbols" do

      let(:key) { :white }
      let(:val) { "ffffff" }
      let(:bad_key) { :black }

      before do
        doc[key] = val
      end

      it_behaves_like "a document with deletable pairs"
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
          expect(doc.send(method, "blue")).to be true
        end
      end

      context "when the key does not exist" do

        it "returns false" do
          expect(doc.send(method, "indigo")).to be false
        end
      end

      context "when the key exists and is requested with a symbol" do

        it "returns true" do
          expect(doc.send(method, :blue)).to be true
        end
      end

      context "when the key does not exist and is requested with a symbol" do

        it "returns false" do
          expect(doc.send(method, :indigo)).to be false
        end
      end
    end
  end

  [ :has_value?, :value? ].each do |method|

    describe "##{method}" do

      let(:key) { :purple }
      let(:val) { :'5422a8' }

      before do
        doc[key] = val
      end

      context "when the value exists" do

        it "returns true" do
          expect(doc.send(method, "000099")).to be true
        end
      end

      context "when the value does not exist" do

        it "returns false" do
          expect(doc.send(method, "ABCABC")).to be false
        end
      end

      context "when the value exists and is requested with a symbol" do

        it "returns true" do

          expect(doc.send(method, :'5422a8')).to be true
        end
      end

      context "when the value does not exist and is requested with a symbol" do

        it "returns false" do
          expect(doc.send(method, :ABCABC)).to be false
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

    context "and the documents have no common keys" do
      before { other[:a] = 1 }

      it "does not execute the block" do
        expect(other.merge(b: 1) { |key, old, new| old + new }).to eq(
          BSON::Document.new(a: 1, b: 1)
        )
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

    context "when providing symbol keys" do

      let(:document) do
        described_class.new(:test => 2, :testing => 4)
      end

      it "converts the symbols to strings" do
        expect(document).to eq({ "test" => 2, "testing" => 4 })
      end
    end

    context "when providing duplicate symbol and string keys" do

      let(:document) do
        described_class.new(:test => 2, "test" => 4)
      end

      it "uses the last provided string key value" do
        expect(document[:test]).to eq(4)
      end
    end

    context "when providing a nested hash with symbol keys" do

      let(:document) do
        described_class.new(:test => { :test => 4 })
      end

      it "converts the nested keys to strings" do
        expect(document).to eq({ "test" => { "test" => 4 }})
      end
    end

    context "when providing a nested hash multiple levels deep with symbol keys" do

      let(:document) do
        described_class.new(:test => { :test => { :test => 4 }})
      end

      it "converts the nested keys to strings" do
        expect(document).to eq({ "test" => { "test" => { "test" => 4 }}})
      end
    end

    context "when providing an array of nested hashes" do

      let(:document) do
        described_class.new(:test => [{ :test => 4 }])
      end

      it "converts the nested keys to strings" do
        expect(document).to eq({ "test" => [{ "test" => 4 }]})
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
      expect(updated.keys).to eq([ "name" ])
    end

    it "updates the values" do
      expect(updated.values).to eq([ "Bob" ])
    end

    it "returns the same document" do
      expect(updated.update(:name => "Bob")).to equal(updated)
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

  describe "#from_bson" do

    context "when the document has embedded documents in an array" do

      let(:embedded_document) do
        BSON::Document.new(n: 1)
      end

      let(:embedded_documents) do
        [ embedded_document ]
      end

      let(:document) do
        BSON::Document.new(field: 'value', embedded: embedded_documents)
      end

      let(:serialized) do
        document.to_bson.to_s
      end

      let(:deserialized) do
        described_class.from_bson(BSON::ByteBuffer.new(serialized))
      end

      it 'deserializes the documents' do
        expect(deserialized).to eq(document)
      end

      it 'deserializes embedded documents as document type' do
        expect(deserialized[:embedded].first).to be_a(BSON::Document)
      end
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
        expect(obj.to_bson.to_s).to eq(bson)
      end
    end

    context "when the hash contains an array of hashes" do
      let(:obj) do
        described_class["key",[{"a" => 1}, {"b" => 2}]]
      end

      let(:bson) do
        "#{45.to_bson}#{Array::BSON_TYPE}key#{BSON::NULL_BYTE}" +
        "#{35.to_bson}"+
        "#{BSON::Document::BSON_TYPE}0#{BSON::NULL_BYTE}#{12.to_bson}#{BSON::Int32::BSON_TYPE}a#{BSON::NULL_BYTE}#{1.to_bson}#{BSON::NULL_BYTE}" +
        "#{BSON::Document::BSON_TYPE}1#{BSON::NULL_BYTE}#{12.to_bson}#{BSON::Int32::BSON_TYPE}b#{BSON::NULL_BYTE}#{2.to_bson}#{BSON::NULL_BYTE}" +
        "#{BSON::NULL_BYTE}" +
        "#{BSON::NULL_BYTE}"
      end

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
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
        BSON::ByteBuffer.new(bson)
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

      let(:deserialized) do
        described_class.from_bson(BSON::ByteBuffer.new(document.to_bson.to_s))
      end

      it "serializes and deserializes properly" do
        expect(deserialized['type'].compile).to eq(/^gültig/)
      end
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

    context "given a utf-8-encodable string in another encoding" do

      let(:string) { "gültig" }
      let(:document) do
        described_class["type", string.encode("iso-8859-1")]
      end

      it 'converts the values to utf-8' do
        expect(
          BSON::Document.from_bson(BSON::ByteBuffer.new(document.to_bson.to_s))
        ).to eq({ "type" => string })
      end
    end

    context "given a binary string with utf-8 values" do

      let(:string) { "europäisch".force_encoding('binary') }
      let(:document) do
        described_class["type", string]
      end

      it "raises encoding error" do
        expect do
          document.to_bson
        end.to raise_error(Encoding::UndefinedConversionError, /from ASCII-8BIT to UTF-8/)
      end
    end
  end
end
