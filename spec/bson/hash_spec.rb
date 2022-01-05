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

    context 'with symbol values' do
      let(:value) { :foo }

      let(:serialized) do
        {foo: value}.to_bson.to_s
      end

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

      let(:bson_with_symbol) do
        "\x12\x00\x00\x00\x0Efoo\x00\x04\x00\x00\x00bar\x00\x00".force_encoding('binary')
      end

      let(:deserialized) do
        Hash.from_bson(BSON::ByteBuffer.new(bson_with_symbol))
      end

      context 'when Symbol#bson_type is set to symbol' do
        let(:bson_type_to_use) { BSON::Symbol::BSON_TYPE }

        let(:expected) do
          "\x12\x00\x00\x00\x0Efoo\x00\x04\x00\x00\x00foo\x00\x00".force_encoding('binary')
        end

        it 'serializes to BSON symbol' do
          perform_test(bson_type_to_use) do
            serialized
          end.should == expected
        end

        it 'deserializes to Symbol' do
          deserialized.should == {'foo' => :bar}
        end
      end

      context 'when Symbol#bson_type is set to string' do
        let(:bson_type_to_use) { BSON::String::BSON_TYPE }

        let(:expected) do
          "\x12\x00\x00\x00\x02foo\x00\x04\x00\x00\x00foo\x00\x00".force_encoding('binary')
        end

        it 'serializes to BSON string' do
          perform_test(bson_type_to_use) do
            serialized
          end.should == expected
        end

        it 'deserializes to Symbol' do
          deserialized.should == {'foo' => :bar}
        end
      end
    end

    context 'when hash contains value of an unserializable class' do
      class HashSpecUnserializableClass
      end

      let(:obj) do
        {foo: HashSpecUnserializableClass.new}
      end

      it 'raises UnserializableClass' do
        lambda do
          obj.to_bson
        end.should raise_error(BSON::Error::UnserializableClass,
          # C extension does not provide hash key in the exception message.
          /(Hash value for key 'foo'|Value) does not define its BSON serialized type:.*HashSpecUnserializableClass/)
      end
    end

    context 'when reading from a byte buffer that was previously written to' do
      let(:buffer) do
        {foo: 42}.to_bson
      end

      it 'returns the original hash' do
        expect(Hash.from_bson(buffer)).to eq('foo' => 42)
      end
    end

    context 'when round-tripping a BigDecimal' do
      let(:to_bson) do
        {"x" => BigDecimal('1')}.to_bson
      end

      let(:from_bson) do
        Hash.from_bson(to_bson)
      end

      it 'doesn\'t raise on serialization' do
        expect do
          to_bson
        end.to_not raise_error
      end

      it 'deserializes as a BSON::Decimal128' do
        expect(from_bson).to eq({"x" => BSON::Decimal128.new('1')})
      end
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

    context 'when serializing a hash with a BigDecimal' do
      let(:hash) do
        {'foo' => BigDecimal('1')}
      end

      it 'works' do
        expect do
          hash.to_bson
        end.not_to raise_error
      end
    end
  end

  describe '#from_bson' do
    context 'when bson document has duplicate keys' do
      let(:buf) do
        buf = BSON::ByteBuffer.new
        buf.put_int32(37)
        buf.put_byte("\x02")
        buf.put_cstring('foo')
        buf.put_string('bar')
        buf.put_byte("\x02")
        buf.put_cstring('foo')
        buf.put_string('overwrite')
        buf.put_byte("\x00")

        BSON::ByteBuffer.new(buf.to_s)
      end

      let(:doc) { Hash.from_bson(buf) }

      it 'overwrites first value with second value' do
        doc.should == {'foo' => 'overwrite'}
      end
    end

    context 'when bson document has string and symbol keys of the same name' do
      let(:buf) do
        buf = BSON::ByteBuffer.new
        buf.put_int32(31)
        buf.put_byte("\x02")
        buf.put_cstring('foo')
        buf.put_string('bar')
        buf.put_byte("\x0e")
        buf.put_cstring('foo')
        buf.put_string('bar')
        buf.put_byte("\x00")

        BSON::ByteBuffer.new(buf.to_s)
      end

      let(:doc) { Hash.from_bson(buf) }

      it 'overwrites first value with second value' do
        doc.should == {'foo' => :bar}
      end
    end
  end
end
