require "spec_helper"

describe BSON::Int32 do

  describe "::INT32_TYPE" do

    it "returns 0x10" do
      expect(Integer::INT32_TYPE).to eq(16.chr)
    end
  end

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(Integer::INT32_TYPE)
    end

    it "registers the int32 type" do
      expect(registered).to eq(described_class)
    end
  end
end