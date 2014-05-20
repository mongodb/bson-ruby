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

describe BSON::Boolean do

  describe "::BSON_TYPE" do

    it "returns 8" do
      expect(BSON::Boolean::BSON_TYPE).to eq(8.chr)
    end
  end

  describe "#from_bson" do

    let(:type) { 8.chr }

    it_behaves_like "a bson element"

    context "when the boolean is true" do

      let(:obj)  { true }
      let(:bson) { 1.chr }

      it_behaves_like "a deserializable bson element"
    end

    context "when the boolean is false" do

      let(:obj)  { false }
      let(:bson) { 0.chr }

      it_behaves_like "a deserializable bson element"
    end
  end
end
