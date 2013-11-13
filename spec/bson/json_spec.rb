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

describe BSON::JSON do

  describe "#to_json" do

    let(:klass) do
      Class.new do
        include BSON::JSON

        def as_json(*args)
          { :test => "value" }
        end
      end
    end

    context "when provided no arguments" do

      let(:json) do
        klass.new.to_json
      end

      it "returns the object as json" do
        expect(json).to eq("{\"test\":\"value\"}")
      end
    end

    context "when provided arguments" do

      let(:json) do
        klass.new.to_json(:test)
      end

      it "returns the object as json" do
        expect(json).to eq("{\"test\":\"value\"}")
      end
    end
  end
end
