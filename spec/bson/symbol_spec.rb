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

describe Symbol do

  describe "#to_bson/#from_bson" do

    let(:type) { 14.chr }
    let(:obj)  { :test }
    let(:bson) { "#{5.to_bson}test#{BSON::NULL_BYTE}" }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"

  end

  describe "#to_bson_key" do

    let(:symbol) { :test }
    let(:encoded) { symbol.to_s + BSON::NULL_BYTE }
    let(:previous_content) { 'previous_content'.force_encoding(BSON::BINARY) }

    it "returns the encoded string" do
      expect(symbol.to_bson_key).to eq(encoded)
    end

    it "appends to optional previous content" do
      expect(symbol.to_bson_key(previous_content)).to eq(previous_content << encoded)
    end

    context 'when the symbol contains a null byte' do
      let(:symbol) { :"test#{BSON::NULL_BYTE}ing" }

      it 'raises an error' do
        expect {
          symbol.to_bson_key
        }.to raise_error(ArgumentError)
      end
    end
  end
end
