# encoding: utf-8
require "spec_helper"

describe BSON::Binary do

  describe "#==" do

    let(:binary) do
      described_class.new(:md5, "test")
    end

    context "when the objects are equal" do

      let(:other) do
        described_class.new(:md5, "test")
      end

      it "returns true" do
        expect(binary).to eq(other)
      end
    end

    context "when the objects are not equal" do

      let(:other) do
        described_class.new(:generic, "test")
      end

      it "returns false" do
        expect(binary).to_not eq(other)
      end
    end

    context "when the other object is not a binary" do

      it "returns false" do
        expect(binary).to_not eq("test")
      end
    end
  end

  describe "::BSON_TYPE" do

    it "returns 0x05" do
      expect(BSON::Binary::BSON_TYPE).to eq(5.chr)
    end
  end

  describe "#bson_type" do

    let(:binary) do
      described_class.new(:md5, "test")
    end

    it "returns 0x0D" do
      expect(binary.bson_type).to eq(BSON::Binary::BSON_TYPE)
    end
  end

  describe "#initialize" do

    let(:data) do
      "testing"
    end

    let(:binary) do
      described_class.new(:md5, data)
    end

    it "sets the type" do
      expect(binary.type).to eq(:md5)
    end

    it "sets the data" do
      expect(binary.data).to eq(data)
    end
  end

  describe "#to_bson" do

    context "when the type is generic" do

      let(:binary) do
        described_class.new(:generic, "testing")
      end

      let(:encoded) do
        binary.to_bson
      end

      it "serialized the length, subtype and bytes" do
        expect(encoded).to eq("#{7.to_bson}#{0.chr}testing")
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the type is function" do

      let(:binary) do
        described_class.new(:function, "testing")
      end

      let(:encoded) do
        binary.to_bson
      end

      it "serialized the length, subtype and bytes" do
        expect(encoded).to eq("#{7.to_bson}#{1.chr}testing")
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the type is the old default" do

      let(:binary) do
        described_class.new(:old, "testing")
      end

      let(:encoded) do
        binary.to_bson
      end

      it "serialized the length, subtype and bytes" do
        expect(encoded).to eq("#{7.to_bson}#{2.chr}testing")
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the type is the old uuid" do

      let(:binary) do
        described_class.new(:uuid_old, "testing")
      end

      let(:encoded) do
        binary.to_bson
      end

      it "serialized the length, subtype and bytes" do
        expect(encoded).to eq("#{7.to_bson}#{3.chr}testing")
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the type is uuid" do

      let(:binary) do
        described_class.new(:uuid, "testing")
      end

      let(:encoded) do
        binary.to_bson
      end

      it "serialized the length, subtype and bytes" do
        expect(encoded).to eq("#{7.to_bson}#{4.chr}testing")
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the type is md5" do

      let(:binary) do
        described_class.new(:md5, "testing")
      end

      let(:encoded) do
        binary.to_bson
      end

      it "serialized the length, subtype and bytes" do
        expect(encoded).to eq("#{7.to_bson}#{5.chr}testing")
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the type is user" do

      let(:binary) do
        described_class.new(:user, "testing")
      end

      let(:encoded) do
        binary.to_bson
      end

      it "serialized the length, subtype and bytes" do
        expect(encoded).to eq("#{7.to_bson}#{128.chr}testing")
      end

      it_behaves_like "a binary encoded string"
    end
  end

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(BSON::Binary::BSON_TYPE)
    end

    it "registers the type" do
      expect(registered).to eq(described_class)
    end
  end
end
