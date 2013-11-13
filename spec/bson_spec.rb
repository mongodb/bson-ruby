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

describe BSON do

  describe "::BINARY" do

    it "returns BINARY" do
      expect(BSON::BINARY).to eq("BINARY")
    end
  end

  describe "::NO_VAUE" do

    it "returns an empty string" do
      expect(BSON::NO_VALUE).to be_empty
    end
  end

  describe "::NULL_BYTE" do

    it "returns the char 0x00" do
      expect(BSON::NULL_BYTE).to eq(0.chr)
    end
  end

  describe "::UTF8" do

    it "returns UTF-8" do
      expect(BSON::UTF8).to eq("UTF-8")
    end
  end
end
