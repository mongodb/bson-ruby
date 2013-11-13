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

describe Array do

  describe "#to_bson/#from_bson" do

    let(:type) { 4.chr }
    let(:obj)  {[ "one", "two" ]}
    let(:bson) do
      BSON::Document["0", "one", "1", "two"].to_bson
    end

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
  end

  describe "#to_bson_object_id" do

    context "when the array has 12 elements" do

      let(:array) do
        [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 ]
      end

      let(:converted) do
        array.to_bson_object_id
      end

      it "returns the array as a string" do
        expect(converted).to eq(array.pack("C*"))
      end
    end

    context "when the array does not have 12 elements" do

      it "raises an exception" do
        expect {
          [ 1 ].to_bson_object_id
        }.to raise_error(BSON::ObjectId::Invalid)
      end
    end
  end
end
