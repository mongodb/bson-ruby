# encoding: utf-8
require "spec_helper"

describe BSON::Registry do

  describe ".get" do

    context "when the type has a correspoding class" do

      before do
        described_class.register(BSON::MinKey::BSON_TYPE, BSON::MinKey)
      end

      let(:klass) do
        described_class.get(BSON::MinKey::BSON_TYPE)
      end

      it "returns the class" do
        expect(klass).to eq(BSON::MinKey)
      end
    end

    context "when the type has no corresponding class" do

      if ordered_hash_support?

        it "raises an error" do
          expect {
            described_class.get("test")
          }.to raise_error(KeyError)
        end
      else

        it "raises an error" do
          expect {
            described_class.get("test")
          }.to raise_error(IndexError)
        end
      end
    end
  end
end
