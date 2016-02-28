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

describe BSON::Registry do

  describe ".get" do

    context "when the type has a correspoding class" do

      before do
        described_class.register(BSON::MinKey::BSON_TYPE, BSON::MinKey)
      end

      let(:klass) do
        described_class.get(BSON::MinKey::BSON_TYPE, "field")
      end

      it "returns the class" do
        expect(klass).to eq(BSON::MinKey)
      end
    end

    context "when the type has no corresponding class" do

      it "raises an error" do
        expect {
          described_class.get(25.chr, "field")
        }.to raise_error(BSON::Registry::UnsupportedType)
      end
    end
  end
end
