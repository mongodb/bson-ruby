require "spec_helper"

describe BSON::CodeWithScope do

  describe "::BSON_TYPE" do

    it "returns 0x0F" do
      expect(BSON::CodeWithScope::BSON_TYPE).to eq(15.chr)
    end
  end

  describe "#bson_type" do

    let(:code_with_scope) do
      described_class.new
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
