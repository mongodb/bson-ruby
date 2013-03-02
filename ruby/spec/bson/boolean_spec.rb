require "spec_helper"

describe BSON::Boolean do

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(BSON::Boolean::BSON_TYPE)
    end

    it "registers the type" do
      expect(registered).to eq(described_class)
    end
  end
end
