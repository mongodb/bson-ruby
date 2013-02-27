require "spec_helper"

describe BSON::Ext::Integer do

  describe "::INT32_PACK" do

    it "returns l" do
      expect(Integer::INT32_PACK).to eq("l")
    end
  end

  describe "::INT32_TYPE" do

    it "returns 0x10" do
      expect(Integer::INT32_TYPE).to eq(16.chr)
    end
  end

  describe "::INT64_TYPE" do

    it "returns 0x12" do
      expect(Integer::INT64_TYPE).to eq(18.chr)
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

      pending "should we raise an error"
    end

    context "when the intger is too small" do

      let(:integer) do
        Integer::MAX_64BIT - 1
      end

      pending "should we raise an error"
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

      it "returns the 32 bit raw bytes" do
        expect(integer.to_bson).to eq(expected)
      end
    end

    context "when the integer is 64 bit" do

      let(:integer) do
        Integer::MAX_64BIT - 1
      end

      let(:expected) do
        [ integer ].pack(Integer::INT64_PACK)
      end

      it "returns the 64 bit raw bytes" do
        expect(integer.to_bson).to eq(expected)
      end
    end

    context "when the integer is too large" do

      let(:integer) do
        Integer::MAX_64BIT + 1
      end

      pending "should we raise an error"
    end

    context "when the intger is too small" do

      let(:integer) do
        Integer::MAX_64BIT - 1
      end

      pending "should we raise an error"
    end
  end

  context "when the class is loaded" do

    let(:registered_small) do
      BSON::Registry.get(Integer::INT32_TYPE)
    end

    let(:registered_large) do
      BSON::Registry.get(Integer::INT64_TYPE)
    end

    it "registers the int32 type" do
      expect(registered_small).to eq(Integer)
    end

    it "registers the int64 type" do
      expect(registered_large).to eq(Integer)
    end
  end
end
