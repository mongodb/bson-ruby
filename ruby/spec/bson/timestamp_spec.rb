require "spec_helper"

describe BSON::Timestamp do

  describe "::BSON_TYPE" do

    it "returns 0x11" do
      expect(BSON::Timestamp::BSON_TYPE).to eq(17.chr)
    end
  end

  describe "#bson_type" do

    let(:timestamp) do
      described_class.new(1, 10)
    end

    it "returns the bson type" do
      expect(timestamp.bson_type).to eq(BSON::Timestamp::BSON_TYPE)
    end
  end

  describe "#to_bson" do

    let(:timestamp) do
      described_class.new(1, 10)
    end

    let(:packed_timestamp) do
      [ 1, 10 ].pack("l2")
    end

    it "returns the encoded timestamp" do
      expect(timestamp.to_bson).to eq(packed_timestamp)
    end
  end
end
