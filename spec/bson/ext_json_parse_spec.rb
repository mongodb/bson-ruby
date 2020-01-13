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

describe "BSON::ExtJSON.parse" do

  let(:parsed) { BSON::ExtJSON.parse_obj(input) }

  context 'when input is true' do
    let(:input) { true }

    it 'returns true' do
      parsed.should == true
    end
  end

  context 'when input is false' do
    let(:input) { false }

    it 'returns false' do
      parsed.should == false
    end
  end

  context 'when input is nil' do
    let(:input) { nil }

    it 'returns nil' do
      parsed.should be nil
    end
  end

  context 'when input is a string' do
    let(:input) { 'hello' }

    it 'returns the string' do
      parsed.should == 'hello'
    end
  end

  context 'when input is a timestamp' do
    let(:input) { {'$timestamp' => {'t' => 12345, 'i' => 42}} }

    it 'returns a timestamp object' do
      parsed.should == BSON::Timestamp.new(12345, 42)
    end
  end

  context 'when input is an int32' do
    let(:input) do
      {'$numberInt' => '42'}
    end

    let(:parsed) { BSON::ExtJSON.parse_obj(input, mode: mode) }

    context 'when :mode is nil' do
      let(:mode) { nil }

      it 'returns Integer instance' do
        parsed.should be_a(Integer)
        parsed.should == 42
      end
    end

    context 'when :mode is :bson' do
      let(:mode) { :bson }

      it 'returns Integer instance' do
        parsed.should be_a(Integer)
        parsed.should == 42
      end
    end
  end

  context 'when input is an int64' do
    let(:input) do
      {'$numberLong' => '42'}
    end

    let(:parsed) { BSON::ExtJSON.parse_obj(input, mode: mode) }

    context 'when :mode is nil' do
      let(:mode) { nil }

      it 'returns Integer instance' do
        parsed.should be_a(Integer)
        parsed.should == 42
      end
    end

    context 'when :mode is :bson' do
      let(:mode) { :bson }

      it 'returns Int64 instance' do
        parsed.should be_a(BSON::Int64)
        parsed.value.should == 42
      end
    end
  end
end
