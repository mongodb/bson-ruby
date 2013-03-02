# encoding: utf-8
require "spec_helper"

describe BSON::Code do

  describe "#==" do

    let(:code) do
      described_class.new("this.value == 'test'")
    end

    context "when the objects are equal" do

      let(:other) do
        described_class.new("this.value == 'test'")
      end

      it "returns true" do
        expect(code).to eq(other)
      end
    end

    context "when the objects are not equal" do

      let(:other) do
        described_class.new("this.field == 'test'")
      end

      it "returns false" do
        expect(code).to_not eq(other)
      end
    end

    context "when the other object is not a code" do

      it "returns false" do
        expect(code).to_not eq("test")
      end
    end
  end

  describe "::BSON_TYPE" do

    it "returns 0x0D" do
      expect(BSON::Code::BSON_TYPE).to eq(13.chr)
    end
  end

  describe "#bson_type" do

    let(:code) do
      described_class.new("this.value = 5")
    end

    it "returns 0x0D" do
      expect(code.bson_type).to eq(BSON::Code::BSON_TYPE)
    end
  end

  describe "#to_bson" do

    let(:code) do
      described_class.new("this.value = 5")
    end

    let(:encoded) do
      code.to_bson
    end

    it "returns the encoded string" do
      expect(encoded).to eq("#{15.to_bson}this.value = 5#{BSON::NULL_BYTE}")
    end
  end

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(BSON::Code::BSON_TYPE)
    end

    it "registers the type" do
      expect(registered).to eq(described_class)
    end
  end
end
