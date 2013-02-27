require "spec_helper"

describe BSON::Code do

  describe "::BSON_TYPE" do

    it "returns 0x0D" do
      expect(BSON::Code::BSON_TYPE).to eq(13.chr)
    end
  end

  describe "#bson_type" do

    let(:code) do
      described_class.new
    end

    it "returns 0x0D" do
      expect(code.bson_type).to eq(BSON::Code::BSON_TYPE)
    end
  end

  pending "#to_bson"

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(BSON::Code::BSON_TYPE)
    end

    it "registers the type" do
      expect(registered).to eq(described_class)
    end
  end
end
