# frozen_string_literal: true

# Copyright (C) 2026 MongoDB Inc.
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

require 'spec_helper'

describe 'Decoding document fields' do
  def decode(document)
    BSON::Document.from_bson(BSON::ByteBuffer.new(document.to_bson.to_s))
  end

  def datetime_document(millis)
    buffer = BSON::ByteBuffer.new
    buffer.put_int32(16)
    buffer.put_byte(Time::BSON_TYPE)
    buffer.put_cstring('t')
    buffer.put_int64(millis)
    buffer.put_byte(BSON::NULL_BYTE)
    buffer
  end

  context 'when the field is null' do
    it 'decodes to nil' do
      decoded = decode('a' => nil, 'b' => [ nil, { 'c' => nil } ])
      expect(decoded).to eq('a' => nil, 'b' => [ nil, { 'c' => nil } ])
    end
  end

  context 'when the field is an object id' do
    let(:id) { BSON::ObjectId.new }
    let(:decoded) { decode('_id' => id, 'ids' => [ id ])['_id'] }

    it 'decodes to an equal object id' do
      expect(decoded).to eq(id)
      expect(decoded).to be_a(BSON::ObjectId)
    end

    it 'decodes to the same object that ObjectId.from_bson builds' do
      expected = BSON::ObjectId.from_bson(BSON::ByteBuffer.new(id.to_bson.to_s))
      expect(Marshal.dump(decoded)).to eq(Marshal.dump(expected))
      expect(decoded.generation_time).to eq(id.generation_time)
    end
  end

  context 'when the field is a datetime' do
    [
      0, 1, -1, 999, 1000, -999, -1000, -1001, 1_700_000_000_123, -86_400_500,
      253_402_300_799_999, -62_135_596_800_000, (2**53) + 1, -(2**53) - 1
    ].each do |millis|
      context "when it is #{millis} milliseconds from the epoch" do
        let(:decoded) { BSON::Document.from_bson(datetime_document(millis))['t'] }
        let(:expected) { Time.from_bson(BSON::ByteBuffer.new([ millis ].pack('q<'))) }

        it 'decodes to the same time that Time.from_bson builds' do
          expect(decoded).to eq(expected)
          expect(decoded.nsec).to eq(expected.nsec)
          expect(Marshal.dump(decoded)).to eq(Marshal.dump(expected))
        end

        it 'decodes to a UTC time' do
          expect(decoded).to be_utc
          expect(decoded.utc_offset).to eq(0)
        end
      end
    end

    it 'consumes the whole value' do
      buffer = datetime_document(1_700_000_000_123)
      BSON::Document.from_bson(buffer)
      expect(buffer.length).to eq(0)
    end
  end

  context 'when the value is cut short' do
    def without_last_value_bytes(document, count)
      bytes = document.to_bson.to_s
      [ bytes.bytesize - count ].pack('l<').concat(bytes[4...(-count - 1)], BSON::NULL_BYTE)
    end

    it 'raises for an object id' do
      bytes = without_last_value_bytes({ 'a' => BSON::ObjectId.new }, 3)
      expect { BSON::Document.from_bson(BSON::ByteBuffer.new(bytes)) }.to raise_error(StandardError)
    end

    it 'raises for a datetime' do
      bytes = without_last_value_bytes({ 'a' => Time.at(0) }, 3)
      expect { BSON::Document.from_bson(BSON::ByteBuffer.new(bytes)) }.to raise_error(StandardError)
    end
  end

  context 'when another class is registered for a type' do
    let(:custom_class) do
      Class.new do
        attr_reader :millis

        def initialize(millis)
          @millis = millis
        end

        def self.from_bson(buffer, **_options)
          new(buffer.get_int64)
        end
      end
    end

    around do |example|
      custom_class.const_set(:BSON_TYPE, Time::BSON_TYPE)
      BSON::Registry.register(Time::BSON_TYPE, custom_class)
      example.run
    ensure
      BSON::Registry.register(Time::BSON_TYPE, Time)
    end

    it 'decodes with the registered class' do
      decoded = BSON::Document.from_bson(datetime_document(1234))['t']
      expect(decoded).to be_a(custom_class)
      expect(decoded.millis).to eq(1234)
    end
  end

  context 'when reading field names' do
    let(:decoded) { decode('name' => 1, 'ключ' => { 'name' => 2 }, '' => 3) }

    it 'keeps the names and their order' do
      expect(decoded.keys).to eq([ 'name', 'ключ', '' ])
      expect(decoded['ключ'].keys).to eq([ 'name' ])
    end

    it 'returns frozen UTF-8 names' do
      decoded.each_key do |key|
        expect(key).to be_frozen
        expect(key.encoding).to eq(Encoding::UTF_8)
      end
    end
  end
end
