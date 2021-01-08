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

require "spec_helper"
require "base64"

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
        { "$binary" => {'base64' => Base64.encode64("testing").strip, "subType" => '80' }}
      )
    end

    it_behaves_like "a JSON serializable object"
  end

  describe "#initialize" do

    context 'when type is not given' do
      let(:obj) { described_class.new('foo') }

      it 'defaults to generic type' do
        expect(obj.type).to eq(:generic)
      end
    end

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

      it 'is not binary' do
        # As long as the default Ruby encoding is not binary, the inspected
        # string should also not be in the binary encoding (it should be
        # in one of the text encodings, but which one could depend on
        # the Ruby runtime environment).
        expect(object.inspect.encoding).not_to eq(Encoding::BINARY)
      end

    end

  end

  describe '#from_bson' do
    let(:buffer) { BSON::ByteBuffer.new(bson) }
    let(:obj) { described_class.from_bson(buffer) }

    let(:bson) { "#{5.to_bson}#{0.chr}hello".force_encoding('BINARY') }

    it 'sets data encoding to binary' do
      expect(obj.data.encoding).to eq(Encoding.find('BINARY'))
    end

    context 'when binary subtype is supported' do
      let(:bson) { [3, 0, 0, 0, 1].map(&:chr).join.force_encoding('BINARY') + 'foo' }

      it 'works' do
        obj.should be_a(described_class)
        obj.type.should be :function
      end
    end

    context 'when binary subtype is not supported' do
      let(:bson) { [3, 0, 0, 0, 16].map(&:chr).join.force_encoding('BINARY') + 'foo' }

      it 'raises an exception' do
        lambda do
          obj
        end.should raise_error(BSON::Error::UnsupportedBinarySubtype,
          /BSON data contains unsupported binary subtype 0x10/)
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

    context "when the type is :cyphertext" do
      let(:obj)  { described_class.new("testing", :ciphertext) }
      let(:bson) { "#{7.to_bson}#{6.chr}testing" }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context 'when given binary string' do
      let(:obj) { described_class.new("\x00\xfe\xff".force_encoding('BINARY')) }
      let(:bson) { "#{3.to_bson}#{0.chr}\x00\xfe\xff".force_encoding('BINARY') }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context 'when given a frozen string' do
      let(:str) { "\x00\xfe\xff".force_encoding('BINARY').freeze }
      let(:obj) { described_class.new(str) }
      let(:bson) { "#{3.to_bson}#{0.chr}\x00\xfe\xff".force_encoding('BINARY') }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end
  end

  describe '#to_uuid' do
    let(:obj) { described_class.new("\x00" * 16, :uuid) }

    it 'accepts symbol representation' do
      expect(obj.to_uuid(:standard)).to eq('00000000-0000-0000-0000-000000000000')
    end

    it 'rejects string representation' do
      expect do
        obj.to_uuid('standard')
      end.to raise_error(ArgumentError, /Representation must be given as a symbol/)
    end
  end

  describe '#from_uuid' do
    let(:uuid) { '00000000-0000-0000-0000000000000000' }

    it 'accepts symbol representation' do
      obj = described_class.from_uuid(uuid, :standard)
      expect(obj.data).to eq("\x00" * 16)
    end

    it 'rejects string representation' do
      expect do
        described_class.from_uuid(uuid, 'standard')
      end.to raise_error(ArgumentError, /Representation must be given as a symbol/)
    end
  end
end
