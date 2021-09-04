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

describe DateTime do

  it_behaves_like "a class which converts to Time"

  describe "#to_bson" do

    context "when the date time is post epoch" do

      let(:obj) { DateTime.new(2012, 1, 1, 0, 0, 0) }
      let(:bson) { [ (obj.to_time.to_f * 1000).to_i ].pack(BSON::Int64::PACK) }

      it_behaves_like "a serializable bson element"
    end

    context "when the date time is pre epoch" do

      let(:obj) { DateTime.new(1969, 1, 1, 0, 0, 0) }
      let(:bson) { [ (obj.to_time.to_f * 1000).to_i ].pack(BSON::Int64::PACK) }

      it_behaves_like "a serializable bson element"
    end

    context "when the dates don't both use Gregorian" do

      let(:shakespeare_datetime) do
        DateTime.iso8601('1616-04-23', Date::ENGLAND)
      end

      let(:gregorian_datetime) do
        DateTime.iso8601('1616-04-23', Date::GREGORIAN)
      end

      context "when putting to bson" do

        let(:shakespeare) do
          { a: shakespeare_datetime }.to_bson
        end

        let(:gregorian) do
          { a: gregorian_datetime }.to_bson
        end

        it "does not equal each other" do
          expect(shakespeare.to_s).to_not eq(gregorian.to_s)
        end

        it "the english date is 10 days later" do
          expect(shakespeare.to_s).to eq({ a: DateTime.iso8601('1616-05-03', Date::GREGORIAN) }.to_bson.to_s)
        end
      end

      context "when putting and receiving from bson" do

        let(:shakespeare) do
          Hash.from_bson(BSON::ByteBuffer.new({ a: shakespeare_datetime }.to_bson.to_s))
        end

        let(:gregorian) do
          Hash.from_bson(BSON::ByteBuffer.new({ a: gregorian_datetime }.to_bson.to_s))
        end

        it "does not equal each other" do
          expect(shakespeare).to_not eq(gregorian)
        end

        it "the english date is 10 days later" do
          expect(shakespeare[:a]).to eq(DateTime.iso8601('1616-05-03', Date::GREGORIAN).to_time)
        end

        it "the gregorian date is the same" do
          expect(gregorian[:a]).to eq(DateTime.iso8601('1616-04-23', Date::GREGORIAN).to_time)
        end
      end
    end
  end

  describe '#as_extended_json' do
    let(:object) { DateTime.new(2012, 1, 1, 0, 0, 0.999999) }

    context 'canonical mode' do
      let(:expected_serialization) do
        { '$date' => { '$numberLong' => '1325376000999' } }
      end

      let(:serialization) do
        object.as_extended_json
      end

      it 'truncates to milliseconds when serializing' do
        expect(serialization).to eq expected_serialization
      end

      context 'when value has sub-microsecond precision' do
        let(:object) { DateTime.new(2012, 1, 1, 0, 0, 999_999_999/1_000_000_000r) }

        it 'truncates to milliseconds when serializing' do
          expect(serialization).to eq expected_serialization
        end
      end

      context "when the time precedes epoch" do
        let(:object) { DateTime.new(1960, 1, 1, 0, 0, 0.999999) }

        let(:expected_serialization) do
          { '$date' => { '$numberLong' => '-315619199001' } }
        end

        it 'truncates to milliseconds when serializing' do
          expect(serialization).to eq expected_serialization
        end
      end
    end

    context 'relaxed mode' do
      let(:expected_serialization) do
        { '$date' => '2012-01-01T00:00:00.999Z' }
      end

      let(:serialization) do
        object.as_extended_json(mode: :relaxed)
      end

      it 'truncates to milliseconds when serializing' do
        expect(serialization).to eq expected_serialization
      end

      context 'when value has sub-microsecond precision' do
        let(:object) { DateTime.new(2012, 1, 1, 0, 0, 999_999_999/1_000_000_000r) }

        it 'truncates to milliseconds when serializing' do
          expect(serialization).to eq expected_serialization
        end
      end

      context "when the time precedes epoch" do
        let(:object) { DateTime.new(1960, 1, 1, 0, 0, 0.999999) }

        let(:expected_serialization) do
          { '$date' => { '$numberLong' => '-315619199001' } }
        end

        it 'truncates to milliseconds when serializing' do
          expect(serialization).to eq expected_serialization
        end
      end
    end
  end

  describe '#to_extended_json' do
    let(:object) { DateTime.new(2012, 1, 1, 0, 0, 0.999999) }

    context 'canonical mode' do

      let(:expected_serialization) do
        %q`{"$date":{"$numberLong":"1325376000999"}}`
      end

      let(:serialization) do
        object.to_extended_json
      end

      it 'truncates to milliseconds when serializing' do
        expect(serialization).to eq expected_serialization
      end

      context 'when value has sub-microsecond precision' do
        let(:object) { DateTime.new(2012, 1, 1, 0, 0, 999_999_999/1_000_000_000r) }

        it 'truncates to milliseconds when serializing' do
          expect(serialization).to eq expected_serialization
        end
      end

      context "when the time precedes epoch" do
        let(:object) { DateTime.new(1960, 1, 1, 0, 0, 0.999999) }

        let(:expected_serialization) do
          %q`{"$date":{"$numberLong":"-315619199001"}}`
        end

        it 'truncates to milliseconds when serializing' do
          expect(serialization).to eq expected_serialization
        end
      end
    end

    context 'relaxed mode' do
      let(:expected_serialization) do
        %q`{"$date":"2012-01-01T00:00:00.999Z"}`
      end

      let(:serialization) do
        object.to_extended_json(mode: :relaxed)
      end

      it 'truncates to milliseconds when serializing' do
        expect(serialization).to eq expected_serialization
      end

      context 'when value has sub-microsecond precision' do
        let(:object) { DateTime.new(2012, 1, 1, 0, 0, 999_999_999/1_000_000_000r) }

        it 'truncates to milliseconds when serializing' do
          expect(serialization).to eq expected_serialization
        end
      end
    end
  end

  describe '#to_json' do
    let(:object) { DateTime.new(2012, 1, 1, 0, 0, 0.999999) }

    let(:expected_serialization) do
      %q`"2012-01-01T00:00:00+00:00"`
    end

    let(:serialization) do
      object.to_json
    end

    it 'truncates to milliseconds when serializing' do
      expect(serialization).to eq expected_serialization
    end

    context 'when value has sub-microsecond precision' do
      let(:object) { DateTime.new(2012, 1, 1, 0, 0, 999_999_999/1_000_000_000r) }

      it 'truncates to milliseconds when serializing' do
        expect(serialization).to eq expected_serialization
      end
    end

    context "when the time precedes epoch" do
      let(:object) { DateTime.new(1960, 1, 1, 0, 0, 0.999999) }

      let(:expected_serialization) do
        %q`"1960-01-01T00:00:00+00:00"`
      end

      it 'truncates to milliseconds when serializing' do
        expect(serialization).to eq expected_serialization
      end
    end
  end
end
