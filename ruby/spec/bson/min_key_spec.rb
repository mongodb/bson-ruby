require "spec_helper"

describe BSON::MinKey do

  describe "::BSON_TYPE" do

    it "returns 0xFF" do
      expect(BSON::MinKey::BSON_TYPE).to eq(255.chr)
    end
  end

  describe "#bson_type" do

    let(:min_key) do
      described_class.new
    end

    it "returns 0xFF" do
      expect(min_key.bson_type).to eq(BSON::MinKey::BSON_TYPE)
    end
  end

  describe "#to_bson" do

    let(:min_key) do
      described_class.new
    end

    it "returns an empty string" do
      expect(min_key.to_bson).to be_empty
    end
  end
end
