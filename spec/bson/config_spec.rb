require "spec_helper"

describe BSON::Config do

  describe "#validating_keys?" do

    context "when the default is used" do

      it "returns false" do
        expect(described_class).to_not be_validating_keys
      end
    end

    context "when configuring to false" do

      before do
        BSON::Config.validating_keys = false
      end

      it "returns false" do
        expect(described_class).to_not be_validating_keys
      end
    end

    context "when configuring to true" do

      before do
        BSON::Config.validating_keys = true
      end

      after do
        BSON::Config.validating_keys = false
      end

      it "returns true" do
        expect(described_class).to be_validating_keys
      end
    end
  end
end
