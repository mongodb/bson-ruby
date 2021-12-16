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

  context 'when input is a BSON timestamp' do
    let(:input) { {'$timestamp' => {'t' => 12345, 'i' => 42}} }

    it 'returns a BSON::Timestamp instance' do
      parsed.should == BSON::Timestamp.new(12345, 42)
    end
  end

  context 'when input is an ISO time' do
    let(:input) { {'$date' => '1970-01-01T00:00:04Z'} }

    it 'returns a Time instance ' do
      parsed.should be_a(Time)
    end

    it 'returns a Time instance with correct value' do
      parsed.should == Time.at(4)
    end

    it 'returns a Time instance in UTC' do
      parsed.zone.should == 'UTC'
    end
  end

  context 'when input is a Unix timestamp' do
    let(:input) { {'$date' => {'$numberLong' => '4000'}} }

    it 'returns a Time instance ' do
      parsed.should be_a(Time)
    end

    it 'returns a Time instance with correct value' do
      parsed.should == Time.at(4)
    end

    it 'returns a Time instance in UTC' do
      parsed.zone.should == 'UTC'
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

  context 'when input is a hash' do
    let(:input) do
      {}
    end

    let(:parsed) { BSON::ExtJSON.parse_obj(input, mode: mode) }
    let(:mode) { :bson }

    context 'when mode is invalid' do
      let(:mode) { :foo }

      it 'raises an exception' do
        lambda do
          parsed
        end.should raise_error(ArgumentError, /Invalid value for :mode option/)
      end
    end

    context 'when it contains a string key with a null byte' do
      let(:input) do
        { "key\x00" => 1 }
      end

      it 'raises an exception' do
        lambda do
          parsed
        end.should raise_error(BSON::Error::ExtJSONParseError, /Hash key cannot contain a null byte/)
      end
    end

    context 'when it contains a symbol key with a null byte' do
      let(:input) do
        { "key\x00".to_sym => 1 }
      end

      it 'raises an exception' do
        lambda do
          parsed
        end.should raise_error(BSON::Error::ExtJSONParseError, /Hash key cannot contain a null byte/)
      end
    end

    context 'when it contains an integer key' do
      let(:input) do
        { 0 => 1 }
      end

      it 'does not raises an exception' do
        lambda do
          parsed
        end.should_not raise_error
      end
    end
  end

  context 'when input is a binary' do
    let(:data) do
      Base64.decode64("//8=")
    end

    context 'in current format' do
      let(:input) do
        { "$binary" => { "base64"=>"//8=", "subType"=>"00" } }
      end

      context 'when :mode is nil' do
        let(:mode) { nil }

        it 'returns BSON::Binary instance' do
          parsed.should be_a(BSON::Binary)
          parsed.data.should == data
        end
      end

      context 'when mode is :bson' do
        let(:mode) { :bson }

        it 'returns BSON::Binary instance' do
          parsed.should be_a(BSON::Binary)
          parsed.data.should == data
        end
      end
    end

    context 'in legacy format' do
      let(:input) do
        { "$binary"=>"//8=", "$type"=>"00" }
      end

      context 'when :mode is nil' do
        let(:mode) { nil }

        it 'returns BSON::Binary instance' do
          parsed.should be_a(BSON::Binary)
          parsed.data.should == data
        end
      end

      context 'when mode is :bson' do
        let(:mode) { :bson }

        it 'returns BSON::Binary instance' do
          parsed.should be_a(BSON::Binary)
          parsed.data.should == data
        end
      end
    end
  end

  context 'when input is a regex' do
    let(:pattern) { 'abc' }
    let(:options) { 'im' }

    context 'in current format' do
      let(:input) do
        { "$regularExpression" => { "pattern" => pattern, "options" => options } }
      end

      context 'when :mode is nil' do
        let(:mode) { nil }

        it 'returns a BSON::Regexp::Raw instance' do
          parsed.should be_a(BSON::Regexp::Raw)
          parsed.pattern.should == pattern
          parsed.options.should == options
        end
      end

      context 'when :mode is :bson' do
        let(:mode) { :bson }

        it 'returns a BSON::Regexp::Raw instance' do
          parsed.should be_a(BSON::Regexp::Raw)
          parsed.pattern.should == pattern
          parsed.options.should == options
        end
      end
    end

    context 'in legacy format' do
      let(:input) do
        { "$regex" => pattern, "$options" => options }
      end

      context 'when :mode is nil' do
        let(:mode) { nil }

        it 'returns a BSON::Regexp::Raw instance' do
          parsed.should be_a(BSON::Regexp::Raw)
          parsed.pattern.should == pattern
          parsed.options.should == options
        end
      end

      context 'when :mode is :bson' do
        let(:mode) { :bson }

        it 'returns a BSON::Regexp::Raw instance' do
          parsed.should be_a(BSON::Regexp::Raw)
          parsed.pattern.should == pattern
          parsed.options.should == options
        end
      end
    end

    context 'when $regularExpression is nested in $regex' do
      context 'with options' do
        let(:input) do
          {
            "$regex" => {
              "$regularExpression" => { "pattern" => "foo*", "options" => "" },
            },
            "$options" => "ix",
          }
        end

        it 'parses' do
          parsed.should == {
            '$regex' => BSON::Regexp::Raw.new('foo*'), '$options' => 'ix'
          }
        end
      end

      context 'without options' do
        let(:input) do
          {
            "$regex" => {
              "$regularExpression" => { "pattern" => "foo*", "options" => "" },
            },
          }
        end

        it 'parses' do
          parsed.should == {
            '$regex' => BSON::Regexp::Raw.new('foo*'),
          }
        end
      end
    end
  end
end
