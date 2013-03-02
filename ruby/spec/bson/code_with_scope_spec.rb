# encoding: utf-8
require "spec_helper"

describe BSON::CodeWithScope do

  describe "#==" do

    let(:code_with_scope) do
      described_class.new("this.value == name;", :name => "test")
    end

    context "when the objects are equal" do

      let(:other) do
        described_class.new("this.value == name;", :name => "test")
      end

      it "returns true" do
        expect(code_with_scope).to eq(other)
      end
    end

    context "when the objects are not equal" do

      let(:other) do
        described_class.new("this.value == name;", :value => "test")
      end

      it "returns false" do
        expect(code_with_scope).to_not eq(other)
      end
    end

    context "when the other object is not a code_with_scope" do

      it "returns false" do
        expect(code_with_scope).to_not eq("test")
      end
    end
  end

  describe "::BSON_TYPE" do

    it "returns 0x0F" do
      expect(BSON::CodeWithScope::BSON_TYPE).to eq(15.chr)
    end
  end

  describe "#bson_type" do

    let(:code_with_scope) do
      described_class.new("this.value = name", :name => "test")
    end

    it "returns 0x0F" do
      expect(code_with_scope.bson_type).to eq(BSON::CodeWithScope::BSON_TYPE)
    end
  end

  pending "#to_bson"

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(BSON::CodeWithScope::BSON_TYPE)
    end

    it "registers the type" do
      expect(registered).to eq(described_class)
    end
  end
end
