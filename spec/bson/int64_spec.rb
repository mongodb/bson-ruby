# Copyright (C) 2009-2014 MongoDB Inc.
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

describe BSON::Int64 do

  describe "#intiialize" do

    let(:obj) { described_class.new(integer) }

    context "when the integer is 64-bit" do

      let(:integer) { Integer::MAX_64BIT - 1 }

      it "wraps the integer" do
        expect(obj.instance_variable_get(:@integer)).to be(integer)
      end
    end

    context "when the integer is too large" do

      let(:integer) { Integer::MAX_64BIT + 1 }

      it "raises an out of range error" do
        expect {
          obj
        }.to raise_error(RangeError)
      end
    end

    context "when the integer is too small" do

      let(:integer) { Integer::MIN_64BIT - 1 }

      it "raises an out of range error" do
        expect {
          obj
        }.to raise_error(RangeError)
      end
    end
  end

  describe "#from_bson" do

    let(:type) { 18.chr }
    let(:obj)  { 1325376000000 }
    let(:bson) { [ obj ].pack(BSON::Int64::PACK) }

    it_behaves_like "a bson element"
    it_behaves_like "a deserializable bson element"


    context "when the integer is within the MRI Fixnum range" do

      let(:integer) { 2**30 - 1 }

      let(:bson) do
        BSON::ByteBuffer.new(BSON::Int64.new(integer).to_bson.to_s)
      end

      context "when on JRuby", if: BSON::Environment.jruby? do

        it "deserializes to a Fixnum object" do
          expect(described_class.from_bson(bson).class).to be(Fixnum)
        end
      end

      context "when using MRI < 2.4", if: (!BSON::Environment.jruby? && RUBY_VERSION < '2.4') do

        it "deserializes to a Fixnum object" do
          expect(described_class.from_bson(bson).class).to be(Fixnum)
        end
      end

      context "when using MRI >= 2.4", if: (!BSON::Environment.jruby? && RUBY_VERSION >= '2.4') do

        it "deserializes to an Integer object" do
          expect(described_class.from_bson(bson).class).to be(Integer)
        end
      end
    end

    context "when the 64-bit integer is the BSON max and thus larger than the MRI Fixnum range on all architectures" do

      let(:integer) { Integer::MAX_64BIT }

      let(:bson) do
        BSON::ByteBuffer.new(integer.to_bson.to_s)
      end

      context "when on JRuby", if: BSON::Environment.jruby? do

        it "deserializes to a Fixnum object" do
          expect(described_class.from_bson(bson).class).to be(Fixnum)
        end
      end

      context "when using MRI < 2.4", if: (!BSON::Environment.jruby? && RUBY_VERSION < '2.4') do

        it "deserializes to a Bignum object" do
          expect(described_class.from_bson(bson).class).to be(Bignum)
        end
      end

      context "when using MRI >= 2.4", if: (!BSON::Environment.jruby? && RUBY_VERSION >= '2.4') do

        it "deserializes to an Integer object" do
          expect(described_class.from_bson(bson).class).to be(Integer)
        end
      end
    end
  end

  describe "#to_bson" do

    context "when the integer is 64 bit" do

      let(:type) { 18.chr }
      let(:obj)  { BSON::Int64.new(Integer::MAX_64BIT - 1) }
      let(:bson) { [ Integer::MAX_64BIT - 1 ].pack(BSON::Int64::PACK) }

      it_behaves_like "a serializable bson element"
    end
  end

  describe "#to_bson_key" do

    let(:obj)  {  BSON::Int64.new(Integer::MAX_64BIT - 1) }
    let(:encoded) { (Integer::MAX_64BIT - 1).to_s }

    it "returns the key as a string" do
      expect(obj.to_bson_key).to eq(encoded)
    end
  end
end
