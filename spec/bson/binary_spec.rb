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

describe BSON::Binary do
  let(:testing1)  { described_class.new("testing") }
  let(:testing2)  { described_class.new("testing") }
  let(:not_testing) { described_class.new("not testing") }

  describe "#eql?" do
    context "for two equal objects" do
      it "returns true" do
        expect(testing1).to eql(testing2)
      end
    end

    context "for two different objects" do
      it "returns false" do
        expect(testing1).not_to eql(not_testing)
      end
    end
  end

  describe "#hash" do
    context "for two equal objects" do
      it "is the same" do
        expect(testing1.hash).to eq(testing2.hash)
      end
    end

    context "for two different objects" do
      it "is different" do
        expect(testing1.hash).not_to eq(not_testing.hash)
      end
    end
  end

  let(:hash) do { testing1 => "my value" } end

  it "can be used as Hash key" do
    expect(hash[testing2]).to eq("my value")
    expect(hash[not_testing]).to be_nil
  end

  describe "#as_json" do

    let(:object) do
      described_class.new("testing", :user)
    end

    it "returns the binary data plus type" do
      expect(object.as_json).to eq(
        { "$binary" => "testing", "$type" => :user }
      )
    end

    it_behaves_like "a JSON serializable object"
  end

  describe "#initialize" do

    context "when he type is invalid" do

      it "raises an error" do
        expect {
          described_class.new("testing", :error)
        }.to raise_error { |error|
          expect(error).to be_a(BSON::Binary::InvalidType)
          expect(error.message).to match /is not a valid binary type/
        }
      end
    end
  end

  describe '#inspect' do

    let(:object) do
      described_class.new('testing123', :user)
    end

    it 'returns the truncated data and type' do
      expect(object.inspect).to eq("<BSON::Binary:0x#{object.object_id} type=user data=0x74657374696e6731...>")
    end

    context 'with other encoding' do

      let(:object) do
        described_class.new("\x1F\x8B\b\x00\fxpU\x00\x03\xED\x1C\xDBv\xDB6\xF2\xBD_\x81UN\x9A\xE6T\x96H\xDD-\xDBjR7\xDD\xA6mR\x9F:m\xB7".force_encoding(Encoding::BINARY), :user)
      end

      it 'returns the truncated data and type' do
        expect(object.inspect).to eq("<BSON::Binary:0x#{object.object_id} type=user data=0x1f8b08000c787055...>")
      end

      it 'is not different from default encoding' do
        expect(object.inspect.encoding).not_to eq(Encoding::BINARY)
      end

    end

  end

  describe "#to_bson/#from_bson" do

    let(:type) { 5.chr }

    it_behaves_like "a bson element"

    context "when the type is :generic" do

      let(:obj)  { described_class.new("testing") }
      let(:bson) { "#{7.to_bson}#{0.chr}testing" }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :function" do

      let(:obj)  { described_class.new("testing", :function) }
      let(:bson) { "#{7.to_bson}#{1.chr}testing" }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :old" do

      let(:obj)  { described_class.new("testing", :old) }
      let(:bson) { "#{11.to_bson}#{2.chr}#{7.to_bson}testing" }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :uuid_old" do

      let(:obj)  { described_class.new("testing", :uuid_old) }
      let(:bson) { "#{7.to_bson}#{3.chr}testing" }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :uuid" do

      let(:obj)  { described_class.new("testing", :uuid) }
      let(:bson) { "#{7.to_bson}#{4.chr}testing" }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :md5" do

      let(:obj)  { described_class.new("testing", :md5) }
      let(:bson) { "#{7.to_bson}#{5.chr}testing" }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :user" do

      let(:obj)  { described_class.new("testing", :user) }
      let(:bson) { "#{7.to_bson}#{128.chr}testing" }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end
  end
end
