# Copyright (C) 2021 MongoDB Inc.
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

# BSON::Document ActiveSupport extensions
describe BSON::Document do
  require_active_support

  describe '#symbolize_keys' do
    context 'string keys' do
      let(:doc) do
        described_class.new('foo' => 'bar')
      end

      it 'works correctly' do
        doc.symbolize_keys.should == {foo: 'bar'}
      end
    end
  end

  describe '#symbolize_keys!' do
    context 'string keys' do
      let(:doc) do
        described_class.new('foo' => 'bar')
      end

      it 'raises ArgumentError' do
        lambda do
          doc.symbolize_keys!
        end.should raise_error(ArgumentError, /symbolize_keys! is not supported on BSON::Document instances/)
      end
    end
  end
end
