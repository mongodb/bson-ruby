require "spec_helper"

require "spec_helper"

describe BSON::MaxKey do

  describe "::BSON_TYPE" do

    it "returns 0xFF" do
      expect(BSON::MaxKey::BSON_TYPE).to eq(127.chr)
    end
  end

  describe "#bson_type" do

    let(:max_key) do
      described_class.new
    end

    it "returns 0xFF" do
      expect(max_key.bson_type).to eq(BSON::MaxKey::BSON_TYPE)
    end
  end

  describe "#to_bson" do

    let(:max_key) do
      described_class.new
    end

    it "returns an empty string" do
      expect(max_key.to_bson).to be_empty
    end
  end
end
