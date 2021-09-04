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

describe Date do

  it_behaves_like "a class which converts to Time"

  describe "#to_bson" do

    context "when the date is post epoch" do

      let(:obj)  { Date.new(2012, 1, 1) }
      let(:time) { Time.utc(2012, 1, 1) }
      let(:bson) { [ (time.to_f * 1000).to_i ].pack(BSON::Int64::PACK) }

      it_behaves_like "a serializable bson element"
    end

    context "when the date is pre epoch" do

      let(:obj)  { Date.new(1969, 1, 1) }
      let(:time) { Time.utc(1969, 1, 1) }
      let(:bson) { [ (time.to_f * 1000).to_i ].pack(BSON::Int64::PACK) }

      it_behaves_like "a serializable bson element"
    end
  end

  describe '#as_extended_json' do

    context 'canonical mode' do

      let(:serialization) do
        obj.as_extended_json
      end

      context 'when the time within epoch' do
        let(:obj) { Date.new(2012, 1, 1) }

        let(:expected_serialization) do
          { "$date" => { "$numberLong" => "1325376000000" } }
        end

        it 'correctly serializes the date' do
          expect(serialization).to eq expected_serialization
        end
      end

      context "when the year precedes epoch" do
        let(:obj) { Date.new(1960, 1, 1) }

        let(:expected_serialization) do
          { "$date" => { "$numberLong" => "-315619200000" } }
        end

        it 'correctly serializes the date' do
          expect(serialization).to eq expected_serialization
        end
      end

      context "when the year exceeds 9999" do
        let(:obj) { Time.utc(10000, 1, 1) }

        let(:expected_serialization) do
          { "$date" => { "$numberLong" => "253402300800000" } }
        end

        it 'correctly serializes the date' do
          expect(serialization).to eq expected_serialization
        end
      end
    end

    context 'relaxed mode' do

      let(:serialization) do
        obj.as_extended_json(mode: :relaxed)
      end

      context 'when the time within epoch' do
        let(:obj) { Date.new(2012, 1, 1) }

        let(:expected_serialization) do
          { "$date" => "2012-01-01T00:00:00Z" }
        end

        it 'correctly serializes the date' do
          expect(serialization).to eq expected_serialization
        end
      end

      context "when the year precedes epoch" do
        let(:obj) { Date.new(1960, 1, 1) }

        let(:expected_serialization) do
          { "$date" => { "$numberLong" => "-315619200000" } }
        end

        it 'correctly serializes the date' do
          expect(serialization).to eq expected_serialization
        end
      end

      context "when the year exceeds 9999" do
        let(:obj) { Time.utc(10000, 1, 1) }

        let(:expected_serialization) do
          { "$date" => { "$numberLong" => "253402300800000" } }
        end

        it 'correctly serializes the date' do
          expect(serialization).to eq expected_serialization
        end
      end
    end
  end

  describe '#to_extended_json' do

    context 'canonical mode' do

      let(:serialization) do
        obj.to_extended_json
      end

      context 'when the time within epoch' do
        let(:obj) { Date.new(2012, 1, 1) }

        let(:expected_serialization) do
          %q`{"$date":{"$numberLong":"1325376000000"}}`
        end

        it 'correctly serializes the date' do
          expect(serialization).to eq expected_serialization
        end
      end

      context "when the year precedes epoch" do
        let(:obj) { Date.new(1960, 1, 1) }

        let(:expected_serialization) do
          %q`{"$date":{"$numberLong":"-315619200000"}}`
        end

        it 'correctly serializes the date' do
          expect(serialization).to eq expected_serialization
        end
      end

      context "when the year exceeds 9999" do
        let(:obj) { Time.utc(10000, 1, 1) }

        let(:expected_serialization) do
          %q`{"$date":{"$numberLong":"253402300800000"}}`
        end

        it 'correctly serializes the date' do
          expect(serialization).to eq expected_serialization
        end
      end
    end

    context 'relaxed mode' do
      let(:obj) { Time.utc(2012, 1, 1) }

      let(:expected_serialization) do
        %q`{"$date":"2012-01-01T00:00:00Z"}`
      end

      let(:serialization) do
        obj.to_extended_json(mode: :relaxed)
      end

      it 'correctly serializes the date' do
        expect(serialization).to eq expected_serialization
      end
    end
  end

  describe '#to_json' do

    let(:obj) { Date.new(2012, 1, 1) }

    let(:expected_serialization) do
      %q`"2012-01-01"`
    end

    let(:serialization) do
      obj.to_json
    end

    it 'correctly serializes the date' do
      expect(serialization).to eq expected_serialization
    end

    it_behaves_like "a JSON serializable object"
  end
end
