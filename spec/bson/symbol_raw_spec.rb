# rubocop:todo all
# Copyright (C) 2020 MongoDB Inc.
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

describe BSON::Symbol::Raw do
  describe '#==' do
    let(:one) { described_class.new('foo') }
    let(:two) { described_class.new('foo') }
    let(:three) { described_class.new('bar') }

    it 'compares equal' do
      one.should == two
    end

    it 'compares not equal' do
      one.should_not == three
    end
  end

  describe '#eql?' do
    let(:one) { described_class.new('foo') }
    let(:two) { described_class.new('foo') }
    let(:three) { described_class.new('bar') }

    it 'compares equal' do
      one.should be_eql(two)
    end

    it 'compares not equal' do
      one.should_not be_eql(three)
    end
  end

  describe '#as_json' do
    let(:object) do
      described_class.new(:foobar)
    end

    it 'returns a string' do
      expect(object.as_json).to eq('foobar')
    end

    it_behaves_like 'a JSON serializable object'
  end

  describe '#as_extended_json' do
    let(:object) do
      described_class.new(:foobar)
    end

    it 'returns the binary data plus type' do
      expect(object.as_extended_json).to eq({ '$symbol' => 'foobar' })
    end

    it_behaves_like 'an Extended JSON serializable object'
  end
end
