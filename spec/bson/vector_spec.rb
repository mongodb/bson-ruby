# frozen_string_literal: true

# Copyright (C) 2025-present MongoDB Inc.
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

require 'spec_helper'

describe BSON::Vector do
  it 'behaves like an Array' do
    expect(described_class.new([ 1, 2, 3 ], :int8)).to be_a(Array)
  end

  describe '#initialize' do
    context 'when padding is not provided' do
      let(:vector) { described_class.new([ 1, 2, 3 ], :int8) }

      it 'sets the padding to 0' do
        expect(vector.padding).to eq(0)
      end
    end
  end
end
