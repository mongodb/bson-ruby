# Copyright (C) 2009-2014 MongoDB Inc.
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

      let(:obj)  { DateTime.new(2012, 1, 1, 0, 0, 0) }
      let(:bson) { [ (obj.to_time.to_f * 1000).to_i ].pack(BSON::Int64::PACK) }

      it_behaves_like "a serializable bson element"
    end

    context "when the date time is pre epoch" do

      let(:obj)  { DateTime.new(1969, 1, 1, 0, 0, 0) }
      let(:bson) { [ (obj.to_time.to_f * 1000).to_i ].pack(BSON::Int64::PACK) }

      it_behaves_like "a serializable bson element"
    end
  end

  describe "#as_extended_json" do

    let(:object)  { DateTime.new(2012, 1, 1, 0, 0, 0) }

    it "returns the corresponding Time object as an Extended JSON hash" do
      expect(object.as_extended_json).to eq(object.to_time.as_extended_json)
    end
  end

  describe "#to_extended_json" do

    let(:object) { DateTime.new(2012, 1, 1, 0, 0, 0) }

    it "returns the corresponding Time object's extended json representation" do
      expect(object.to_extended_json).to eq(object.to_time.to_extended_json)
    end
  end
end
