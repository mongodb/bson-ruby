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

describe Symbol do

  describe "#bson_type" do

    it "returns the type for a string" do
      expect(:type.bson_type).to eq("type".bson_type)
    end
  end

  describe "#to_bson/#from_bson" do

    let(:type) { 2.chr }
    let(:obj)  { :test }
    let(:bson) { "#{5.to_bson.to_s}test#{BSON::NULL_BYTE}" }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"

    context 'canonical deserialization' do
      let(:bson) do
        BSON::ByteBuffer.new(BSON::Symbol::Raw.new(obj).to_bson.to_s)
      end

      let(:deserialized) do
        described_class.from_bson(bson, mode: :bson)
      end

      it 'deserializes to BSON::Symbol::Raw' do
        deserialized.class.should be BSON::Symbol::Raw
      end

      it 'has the correct value' do
        deserialized.to_sym.should be obj
      end
    end

    context 'when changing bson_type' do
      def perform_test(bson_type_to_use)
        Symbol.class_eval do
          alias_method :bson_type_orig, :bson_type
          define_method(:bson_type) do
            bson_type_to_use
          end
        end

        begin
          yield
        ensure
          Symbol.class_eval do
            alias_method :bson_type, :bson_type_orig
            remove_method :bson_type_orig
          end
        end
      end

      let(:value) { :foo }

      let(:serialized) do
        value.to_bson.to_s
      end

      context 'when bson_type is set to symbol' do
        it 'serializes to BSON string' do
          perform_test(BSON::Symbol::BSON_TYPE) do
            serialized
          end.should == "\x04\x00\x00\x00foo\x00".force_encoding('binary')
        end
      end

      context 'when bson_type is set to string' do
        it 'serializes to BSON string' do
          perform_test(BSON::String::BSON_TYPE) do
            serialized
          end.should == "\x04\x00\x00\x00foo\x00".force_encoding('binary')
        end
      end
    end
  end

  describe "#to_bson_key" do

    let(:symbol) { :test }
    let(:encoded) { symbol }

    it "returns the encoded string" do
      expect(symbol.to_bson_key).to eq(encoded)
    end
  end

  describe "#to_bson_key" do

    context "when validating keys" do

      let(:symbol) do
        :'$testing.testing'
      end

      it "raises an exception" do
        expect {
          symbol.to_bson_key(true)
        }.to raise_error(BSON::String::IllegalKey)
      end
    end

    context "when not validating keys" do

      let(:symbol) do
        :'$testing.testing'
      end

      it "allows invalid keys" do
        expect(symbol.to_bson_key).to eq(symbol)
      end
    end
  end
end
