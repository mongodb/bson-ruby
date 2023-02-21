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
      expect(42.0.to_json).to eq('42.0')
    end
  end

  describe '#as_extended_json' do
    let(:object) { 42.0 }

    context 'canonical mode' do
      it 'returns $numberDouble' do
        expect(object.as_extended_json).to eq({'$numberDouble' => '42.0'})
      end
    end

    context 'relaxed mode' do
      let(:serialized) do
        object.as_extended_json(mode: :relaxed)
      end

      it 'returns float' do
        expect(serialized).to be_a(Float)
        expect(serialized).to be_within(0.00001).of(42)
      end
    end

    context 'legacy mode' do
      let(:serialized) do
        object.as_extended_json(mode: :legacy)
      end

      it 'returns float' do
        expect(serialized).to be_a(Float)
        expect(serialized).to be_within(0.00001).of(42)
      end
    end

    it_behaves_like "an Extended JSON serializable object"
  end
end
