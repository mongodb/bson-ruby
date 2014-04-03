# Copyright (C) 2009-2013 MongoDB Inc.
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

    context "when the time is pre epoch" do

      let(:obj)  { Time.utc(1969, 1, 1, 0, 0, 0) }
      let(:bson) { [ (obj.to_f * 1000).to_i ].pack(BSON::Int64::PACK) }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end
  end
end
