# rubocop:todo all
# Copyright (C) 2020 MongoDB Inc.
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

describe BSON::DbPointer do

  let(:ref) { 'db.coll' }
  let(:id) { BSON::ObjectId.from_string('56e1fc72e0c917e9c4714161') }
  let(:object) { described_class.new(ref, id) }

  describe "#initialize" do

    it "stores the ref and the id" do
      expect(object.ref).to eq(ref)
      expect(object.id).to eq(id)
    end

    # RUBY-3936. The DBPointer wire format is a string followed by exactly 12
    # raw bytes, and #to_bson writes the id duck-typed. An id of any other type
    # emits the wrong number of bytes, which reframes the enclosing document
    # for every conforming reader. Reject it at construction instead.
    context "when the id is not an ObjectId" do

      [
        [ 'a binary', BSON::Binary.new('12345678901234567890', :generic) ],
        [ 'a string', '56e1fc72e0c917e9c4714161' ],
        [ 'a hash', { 'a' => 1 } ],
        [ 'an integer', 1 ],
        [ 'nil', nil ],
      ].each do |desc, bad_id|

        context "when the id is #{desc}" do

          it "raises an error" do
            expect do
              described_class.new(ref, bad_id)
            end.to raise_error(ArgumentError, /id must be a BSON::ObjectId/)
          end
        end
      end
    end

    context "when the ref is not a string" do

      [
        [ 'nil', nil ],
        [ 'an integer', 5 ],
        [ 'a symbol', :coll ],
      ].each do |desc, bad_ref|

        context "when the ref is #{desc}" do

          it "raises an error" do
            expect do
              described_class.new(bad_ref, id)
            end.to raise_error(ArgumentError, /ref must be a String/)
          end
        end
      end
    end
  end

  describe "#==" do

    context "when the objects are equal" do
      let(:other) { described_class.new(ref, id) }

      it "returns true" do
        expect(object).to eq(other)
      end
    end

    context "when the refs are not equal" do
      let(:other) { described_class.new('db.other', id) }

      it "returns false" do
        expect(object).to_not eq(other)
      end
    end

    context "when the ids are not equal" do
      let(:other) { described_class.new(ref, BSON::ObjectId.new) }

      it "returns false" do
        expect(object).to_not eq(other)
      end
    end

    context "when the other object is not a DbPointer" do

      it "returns false" do
        expect(object).to_not eq('foo')
      end
    end
  end

  describe "#as_extended_json" do

    it "returns the canonical extended json representation" do
      expect(object.as_extended_json).to eq(
        { '$dbPointer' => { '$ref' => ref, '$id' => { '$oid' => '56e1fc72e0c917e9c4714161' } } }
      )
    end

    it_behaves_like 'an Extended JSON serializable object'
    it_behaves_like '#as_json calls #as_extended_json'
  end

  describe "#to_bson" do

    let(:type) { 12.chr }
    let(:obj) { object }
    let(:bson) do
      "#{(ref.length + 1).to_bson.to_s}#{ref}#{BSON::NULL_BYTE}#{id.to_bson.to_s}"
    end

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"

    it "writes exactly twelve bytes for the id" do
      encoded = obj.to_bson.to_s
      expect(encoded.bytesize - (4 + ref.length + 1)).to eq(12)
    end
  end

  describe "#from_bson" do

    let(:type) { 12.chr }
    let(:obj) { object }
    let(:bson) do
      "#{(ref.length + 1).to_bson.to_s}#{ref}#{BSON::NULL_BYTE}#{id.to_bson.to_s}"
    end

    it_behaves_like "a deserializable bson element"
  end

  describe "round trip through a document" do

    # RUBY-3936. Guards the framing itself: a document containing a DBPointer
    # must read back with exactly the keys the application wrote, with no
    # extra elements recovered from a mis-sized id.
    it "reads back only the fields that were written" do
      doc = BSON::Document.new('a' => object, 'z' => 1)
      round = BSON::Document.from_bson(BSON::ByteBuffer.new(doc.to_bson.to_s))
      expect(round.keys).to eq([ 'a', 'z' ])
      expect(round['a']).to eq(object)
      expect(round['z']).to eq(1)
    end
  end
end
