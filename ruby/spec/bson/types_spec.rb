require "spec_helper"

describe BSON::Types do

  describe ".get" do

    context "when the type has a correspoding class" do

      let(:klass) do
        described_class.get(BSON::MinKey::BSON_TYPE)
      end

      it "returns the class" do
        expect(klass).to eq(BSON::MinKey)
      end
    end

    context "when the type has no corresponding class" do

      it "raises an error" do
        expect {
          described_class.get("test")
        }.to raise_error(KeyError)
      end
    end
  end
end
