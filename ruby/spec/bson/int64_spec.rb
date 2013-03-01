require "spec_helper"

describe BSON::Int64 do

  describe "::INT64_TYPE" do

    it "returns 0x12" do
      expect(Integer::INT64_TYPE).to eq(18.chr)
    end
  end

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(Integer::INT64_TYPE)
    end

    it "registers the int32 type" do
      expect(registered).to eq(described_class)
    end
  end
end