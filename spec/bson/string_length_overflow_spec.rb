# frozen_string_literal: true

# Copyright (C) 2026 MongoDB Inc.
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

# Tests for the fix of RUBY-3894: Heap Buffer Overflow in put_string.
#
# BSON encodes string lengths as int32_t. A Ruby string longer than INT32_MAX
# bytes caused a silent integer truncation in the C extension, which then
# passed the resulting negative value to the UTF-8 validator as size_t, wrapping
# to near UINT64_MAX and driving reads far past the heap allocation.
#
# These tests require approximately 2 GB of free memory and only run when
# STRESS=1 is set in the environment. They are also MRI-only because the bug
# lives in the C native extension.
describe 'BSON string length overflow protection' do
  before(:all) do
    skip 'C native extension not used on JRuby' if BSON::Environment.jruby?
    skip 'Set STRESS=1 to run tests that require ~2 GB of free memory' unless ENV['STRESS'] == '1'
  end

  let(:buffer) { BSON::ByteBuffer.new }

  # 2**31 bytes is one byte past INT32_MAX, which is the smallest input that
  # triggers the int32_t truncation.
  let(:huge_string) { 'A' * (2**31) }

  describe '#put_string' do
    it 'raises ArgumentError instead of overflowing' do
      expect do
        buffer.put_string(huge_string)
      end.to raise_error(ArgumentError, /String length \d+ exceeds BSON maximum/)
    end
  end

  describe '#put_cstring' do
    it 'raises ArgumentError instead of overflowing' do
      expect do
        buffer.put_cstring(huge_string)
      end.to raise_error(ArgumentError, /String length \d+ exceeds BSON maximum/)
    end
  end

  describe '#put_symbol' do
    it 'raises ArgumentError instead of overflowing' do
      expect do
        buffer.put_symbol(huge_string.to_sym)
      end.to raise_error(ArgumentError, /String length \d+ exceeds BSON maximum/)
    end
  end
end
