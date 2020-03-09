# Copyright (C) 2018-2020 MongoDB Inc.
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

context 'when ActiveSupport support is enabled' do
  before do
    unless SpecConfig.instance.active_support?
      skip "ActiveSupport support is not enabled"
    end
  end

  describe 'ActiveSupport::TimeWithZone' do
    let(:cls) { ActiveSupport::TimeWithZone }

    it "shares BSON type with Time" do
      # ActiveSupport::TimeWithZone#new has no 0-argument version
      obj = Time.now.in_time_zone("UTC")
      expect(obj.bson_type).to eq(Time::BSON_TYPE)
    end

    shared_examples_for 'deserializes as expected' do
      it 'deserializes to UTC' do
        # Time zone information is lost during serialization - the time
        # is always serialized in UTC.
        rt_obj = Time.from_bson(obj.to_bson)
        expect(rt_obj.zone).to eq('UTC')
      end

      it 'deserializes to an equal object' do
        rt_obj = Time.from_bson(obj.to_bson)
        expect(rt_obj).to eq(obj)
      end
    end

    describe "#to_bson" do

      context "when the TimeWithZone is not in UTC" do

        let(:obj)  { Time.utc(2012, 12, 12, 0, 0, 0).in_time_zone("Pacific Time (US & Canada)") }
        let(:bson) { [ (obj.utc.to_f * 1000).to_i ].pack(BSON::Int64::PACK) }

        it_behaves_like "a serializable bson element"
        it_behaves_like 'deserializes as expected'
      end

      context "when the TimeWithZone is in UTC" do

        let(:obj)  { Time.utc(2012, 1, 1, 0, 0, 0).in_time_zone("UTC") }
        let(:bson) { [ (obj.utc.to_f * 1000).to_i ].pack(BSON::Int64::PACK) }

        it_behaves_like "a serializable bson element"
        it_behaves_like 'deserializes as expected'
      end
    end
  end
end
