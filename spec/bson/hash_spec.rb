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

describe Hash do

  describe "#to_bson/#from_bson" do

    let(:type) { 3.chr }

    it_behaves_like "a bson element"

    context "when the hash is a single level" do

      let(:obj) do
        { "key" => "value" }
      end

      let(:bson) do
        "#{20.to_bson.to_s}#{String::BSON_TYPE}key#{BSON::NULL_BYTE}" +
        "#{6.to_bson.to_s}value#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}"
      end

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the hash has non-string keys" do

      let(:obj) do
        { 1 => "value" }
      end

      let(:expected) do
        { "1" => "value" }
      end

      it "properly converts to bson" do
        expect(BSON::Document.from_bson(BSON::ByteBuffer.new(obj.to_bson.to_s))).to eq(expected)
      end
    end

    context "when the hash has invalid keys" do

      let(:obj) do
        { "$testing" => "value" }
      end

      context "when validating keys" do

        context "when validating globally" do

          before do
            BSON::Config.validating_keys = true
          end

          after do
            BSON::Config.validating_keys = false
          end

          it "raises an error" do
            expect {
              obj.to_bson
            }.to raise_error(BSON::String::IllegalKey)
          end

          context "when the hash contains an array of documents containing invalid keys" do

            let(:obj) do
              { "array" =>  [{ "$testing" => "value" }] }
            end

            it "raises an error" do
              expect {
                obj.to_bson
              }.to raise_error(BSON::String::IllegalKey)
            end
          end
        end

        context "when validating locally" do

          it "raises an error" do
            expect {
              obj.to_bson(BSON::ByteBuffer.new, true)
            }.to raise_error(BSON::String::IllegalKey)
          end

          context "when the hash contains an array of documents containing invalid keys" do

            let(:obj) do
              { "array" =>  [{ "$testing" => "value" }] }
            end

            it "raises an error" do
              expect {
                obj.to_bson(BSON::ByteBuffer.new, true)
              }.to raise_error(BSON::String::IllegalKey)
            end
          end
        end
      end

      context "when not validating keys" do

        let(:bson) do
          "#{25.to_bson.to_s}#{String::BSON_TYPE}$testing#{BSON::NULL_BYTE}" +
          "#{6.to_bson.to_s}value#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}"
        end

        it "serializes the hash" do
          expect(obj.to_bson.to_s).to eq(bson)
        end

        context "when the hash contains an array of documents containing invalid keys" do

          let(:obj) do
            { "array" =>  [{ "$testing" => "value" }] }
          end

          let(:bson) do
            "#{45.to_bson.to_s}#{Array::BSON_TYPE}array#{BSON::NULL_BYTE}" +
              "#{[{ "$testing" => "value" }].to_bson.to_s}#{BSON::NULL_BYTE}"
          end

          it "serializes the hash" do
            expect(obj.to_bson.to_s).to eq(bson)
          end
        end
      end
    end

    context "when the hash is embedded" do

      let(:obj) do
        { "field" => { "key" => "value" }}
      end

      let(:bson) do
        "#{32.to_bson.to_s}#{Hash::BSON_TYPE}field#{BSON::NULL_BYTE}" +
        "#{20.to_bson.to_s}#{String::BSON_TYPE}key#{BSON::NULL_BYTE}" +
        "#{6.to_bson.to_s}value#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}"
      end

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end
  end

  describe '#to_bson' do
    context 'when a key is not valid utf-8' do
      let(:key) { Utils.make_byte_string([254, 253, 255]) }
      let(:hash) do
        {key => 'foo'}
      end

      let(:expected_message) do
        if BSON::Environment.jruby?
          # Uses JRE conversion to another encoding
          /Error serializing key.*Encoding::UndefinedConversionError/
        else
          # Uses our validator
          /Key.*is not valid UTF-8/
        end
      end

      it 'raises EncodingError' do
        expect do
          hash.to_bson
        end.to raise_error(EncodingError, expected_message)
      end
    end

    context 'when a key contains null bytes' do
      let(:hash) do
        {"\x00".force_encoding('BINARY') => 'foo'}
      end

      it 'raises ArgumentError' do
        expect do
          hash.to_bson
        end.to raise_error(ArgumentError, /[Kk]ey.*contains null bytes/)
      end
    end

    context 'when a value is not valid utf-8' do
      let(:hash) do
        {'foo' => [254, 253, 255].map(&:chr).join.force_encoding('BINARY')}
      end

      let(:expected_message) do
        /from ASCII-8BIT to UTF-8/
      end

      it 'raises EncodingError' do
        expect do
          hash.to_bson
        end.to raise_error(EncodingError, expected_message)
      end
    end

    context 'when a value contains null bytes' do
      let(:hash) do
        {'foo' => "\x00".force_encoding('BINARY')}
      end

      it 'works' do
        expect do
          hash.to_bson
        end.not_to raise_error
      end
    end
  end
end
