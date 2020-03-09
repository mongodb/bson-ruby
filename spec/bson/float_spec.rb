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

describe Float do

  describe "#to_bson/#from_bson" do

    let(:type) { 1.chr }
    let(:obj)  { 1.2332 }
    let(:bson) { [ obj ].pack(Float::PACK) }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
  end

  describe '#to_json' do
    it 'returns float' do
      42.0.to_json.should == '42.0'
    end
  end

  describe '#as_extended_json' do
    context 'canonical mode' do
      it 'returns $numberDouble' do
        42.0.as_extended_json.should == {'$numberDouble' => '42.0'}
      end
    end

    context 'relaxed mode' do
      let(:serialized) do
        42.0.as_extended_json(mode: :relaxed)
      end

      it 'returns float' do
        serialized.should be_a(Float)
        serialized.should be_within(0.00001).of(42)
      end
    end

    context 'legacy mode' do
      let(:serialized) do
        42.0.as_extended_json(mode: :legacy)
      end

      it 'returns float' do
        serialized.should be_a(Float)
        serialized.should be_within(0.00001).of(42)
      end
    end
  end
end
