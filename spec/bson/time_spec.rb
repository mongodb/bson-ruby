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

describe Time do

  describe "#to_bson/#from_bson" do

    let(:type) { 9.chr }

    it_behaves_like "a bson element"

    context "when the time is post epoch" do

      context "when the time has no microseconds" do

        let(:obj)  { Time.utc(2012, 1, 1, 0, 0, 0) }
        let(:bson) { [ (obj.to_i * 1000) + (obj.usec / 1000) ].pack(BSON::Int64::PACK) }

        it_behaves_like "a serializable bson element"
        it_behaves_like "a deserializable bson element"
      end

      context "when the time has microseconds" do

        let(:obj)  { Time.at(Time.utc(2014, 03, 22, 18, 05, 05).to_i, 505000).utc }
        let(:bson) { [ (obj.to_i * 1000) + (obj.usec / 1000) ].pack(BSON::Int64::PACK) }

        it_behaves_like "a serializable bson element"
        it_behaves_like "a deserializable bson element"
      end
    end

    context "when the time precedes epoch" do

      let(:obj)  { Time.utc(1969, 1, 1, 0, 0, 0) }
      let(:bson) { [ (obj.to_f * 1000).to_i ].pack(BSON::Int64::PACK) }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context 'when value has sub-millisecond precision' do
      let(:obj)  { Time.utc(2012, 1, 1, 0, 0, 0, 999_999) }

      let(:expected_round_tripped_obj) do
        Time.utc(2012, 1, 1, 0, 0, 0, 999_000)
      end

      let(:round_tripped_obj) do
        Time.from_bson(obj.to_bson)
      end

      it 'truncates to milliseconds when round-tripping' do
        round_tripped_obj.should == expected_round_tripped_obj
      end
    end
  end

  describe '#as_extended_json' do

    context 'canonical mode' do
      context 'when value has sub-millisecond precision' do
        let(:obj)  { Time.utc(2012, 1, 1, 0, 0, 0, 999_999) }

        let(:expected_serialization) do
          {'$date' => {'$numberLong' => '1325376000999'}}
        end

        let(:serialization) do
          obj.as_extended_json
        end

        shared_examples_for 'truncates to milliseconds when serializing' do
          it 'truncates to milliseconds when serializing' do
            serialization.should == expected_serialization
          end
        end

        it_behaves_like 'truncates to milliseconds when serializing'

        context 'when value has sub-microsecond precision' do
          let(:obj)  { Time.utc(2012, 1, 1, 0, 0, 0, 999_999_999/1000r) }

          it_behaves_like 'truncates to milliseconds when serializing'
        end

        context "when the time precedes epoch" do
          let(:obj)  { Time.utc(1960, 1, 1, 0, 0, 0, 999_999) }

          let(:expected_serialization) do
            {'$date' => {'$numberLong' => '-315619199001'}}
          end

          it_behaves_like 'truncates to milliseconds when serializing'
        end
      end
    end

    context 'relaxed mode' do
      context 'when value has sub-millisecond precision' do
        let(:obj)  { Time.utc(2012, 1, 1, 0, 0, 0, 999_999) }

        let(:expected_serialization) do
          {'$date' => '2012-01-01T00:00:00.999Z'}
        end

        let(:serialization) do
          obj.as_extended_json(mode: :relaxed)
        end

        shared_examples_for 'truncates to milliseconds when serializing' do
          it 'truncates to milliseconds when serializing' do
            serialization.should == expected_serialization
          end
        end

        it_behaves_like 'truncates to milliseconds when serializing'

        context 'when value has sub-microsecond precision' do
          let(:obj)  { Time.utc(2012, 1, 1, 0, 0, 0, 999_999_999/1000r) }

          it_behaves_like 'truncates to milliseconds when serializing'
        end

        context "when the time precedes epoch" do
          let(:obj)  { Time.utc(1960, 1, 1, 0, 0, 0, 999_999) }

          let(:expected_serialization) do
            {'$date' => {'$numberLong' => '-315619199001'}}
          end

          it_behaves_like 'truncates to milliseconds when serializing'
        end
      end
    end
  end

  describe '#to_extended_json' do

    context 'canonical mode' do
      context 'when value has sub-millisecond precision' do
        let(:obj)  { Time.utc(2012, 1, 1, 0, 0, 0, 999_999) }

        let(:expected_serialization) do
          %q`{"$date":{"$numberLong":"1325376000999"}}`
        end

        let(:serialization) do
          obj.to_extended_json
        end

        shared_examples_for 'truncates to milliseconds when serializing' do
          it 'truncates to milliseconds when serializing' do
            serialization.should == expected_serialization
          end
        end

        it_behaves_like 'truncates to milliseconds when serializing'

        context 'when value has sub-microsecond precision' do
          let(:obj)  { Time.utc(2012, 1, 1, 0, 0, 0, 999_999_999/1000r) }

          it_behaves_like 'truncates to milliseconds when serializing'
        end

        context "when the time precedes epoch" do
          let(:obj)  { Time.utc(1960, 1, 1, 0, 0, 0, 999_999) }

          let(:expected_serialization) do
            %q`{"$date":{"$numberLong":"-315619199001"}}`
          end

          it_behaves_like 'truncates to milliseconds when serializing'
        end
      end
    end

    context 'relaxed mode' do
      context 'when value has sub-millisecond precision' do
        let(:obj)  { Time.utc(2012, 1, 1, 0, 0, 0, 999_999) }

        let(:expected_serialization) do
          %q`{"$date":"2012-01-01T00:00:00.999Z"}`
        end

        let(:serialization) do
          obj.to_extended_json(mode: :relaxed)
        end

        shared_examples_for 'truncates to milliseconds when serializing' do
          it 'truncates to milliseconds when serializing' do
            serialization.should == expected_serialization
          end
        end

        it_behaves_like 'truncates to milliseconds when serializing'

        context 'when value has sub-microsecond precision' do
          let(:obj)  { Time.utc(2012, 1, 1, 0, 0, 0, 999_999_999/1000r) }

          it_behaves_like 'truncates to milliseconds when serializing'
        end
      end
    end
  end

  describe '#to_json' do

    context 'when value has sub-millisecond precision' do
      let(:obj)  { Time.utc(2012, 1, 1, 0, 0, 0, 999_999) }

      let(:expected_serialization) do
        %q`"2012-01-01 00:00:00 UTC"`
      end

      let(:serialization) do
        obj.to_json
      end

      shared_examples_for 'truncates to milliseconds when serializing' do
        it 'truncates to milliseconds when serializing' do
          serialization.should == expected_serialization
        end
      end

      it_behaves_like 'truncates to milliseconds when serializing'

      context 'when value has sub-microsecond precision' do
        let(:obj)  { Time.utc(2012, 1, 1, 0, 0, 0, 999_999_999/1000r) }

        it_behaves_like 'truncates to milliseconds when serializing'
      end

      context "when the time precedes epoch" do
        let(:obj)  { Time.utc(1960, 1, 1, 0, 0, 0, 999_999) }

        let(:expected_serialization) do
          %q`"1960-01-01 00:00:00 UTC"`
        end

        it_behaves_like 'truncates to milliseconds when serializing'
      end
    end
  end
end
