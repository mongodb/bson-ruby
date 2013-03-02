# encoding: utf-8
require "spec_helper"

describe BSON::Integer do

  describe "::INT32_PACK" do

    it "returns l" do
      expect(Integer::INT32_PACK).to eq("l")
    end
  end

  describe "#bson_int32?" do

    context "when the integer is 32 bit" do

      let(:integer) do
        Integer::MAX_32BIT - 1
      end

      it "returns true" do
        expect(integer).to be_bson_int32
      end
    end

    context "when the integer is not 32 bit" do

      let(:integer) do
        Integer::MAX_32BIT + 1
      end

      it "returns false" do
        expect(integer).to_not be_bson_int32
      end
    end
  end

  describe "#bson_int64?" do

    context "when the integer is 64 bit" do

      let(:integer) do
        Integer::MAX_64BIT - 1
      end

      it "returns true" do
        expect(integer).to be_bson_int64
      end
    end

    context "when the integer is not 64 bit" do

      let(:integer) do
        Integer::MAX_64BIT + 1
      end

      it "returns false" do
        expect(integer).to_not be_bson_int64
      end
    end
  end

  describe "#bson_type" do

    context "when the integer is 32 bit" do

      let(:integer) do
        Integer::MAX_32BIT - 1
      end

      it "returns the INT32_TYPE" do
        expect(integer.bson_type).to eq(Integer::INT32_TYPE)
      end
    end

    context "when the integer is 64 bit" do

      let(:integer) do
        Integer::MAX_64BIT - 1
      end

      it "returns the INT64_TYPE" do
        expect(integer.bson_type).to eq(Integer::INT64_TYPE)
      end
    end

    context "when the integer is too large" do

      let(:integer) do
        Integer::MAX_64BIT + 1
      end

      it "raises an error" do
        expect {
          integer.bson_type
        }.to raise_error(BSON::Int64::OutOfRange)
      end
    end

    context "when the intger is too small" do

      let(:integer) do
        Integer::MIN_64BIT - 1
      end

      it "raises an error" do
        expect {
          integer.bson_type
        }.to raise_error(BSON::Int64::OutOfRange)
      end
    end
  end

  describe "#to_bson" do

    context "when the integer is 32 bit" do

      let(:integer) do
        Integer::MAX_32BIT - 1
      end

      let(:expected) do
        [ integer ].pack(Integer::INT32_PACK)
      end

      let(:encoded) do
        integer.to_bson
      end

      it "returns the 32 bit raw bytes" do
        expect(encoded).to eq(expected)
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the integer is 64 bit" do

      let(:integer) do
        Integer::MAX_64BIT - 1
      end

      let(:encoded) do
        integer.to_bson
      end

      let(:expected) do
        [ integer ].pack(Integer::INT64_PACK)
      end

      it "returns the 64 bit raw bytes" do
        expect(encoded).to eq(expected)
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the integer is too large" do

      let(:integer) do
        Integer::MAX_64BIT + 1
      end

      it "raises an out of range error" do
        expect {
          integer.to_bson
        }.to raise_error(BSON::Int64::OutOfRange)
      end
    end

    context "when the intger is too small" do

      let(:integer) do
        Integer::MIN_64BIT - 1
      end

      it "raises an out of range error" do
        expect {
          integer.to_bson
        }.to raise_error(BSON::Int64::OutOfRange)
      end
    end
  end
end
