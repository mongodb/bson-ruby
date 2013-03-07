# encoding: utf-8
require "spec_helper"

module BSON
  describe MaxKey do
    let(:type) { 127.chr }
    let(:obj)  { described_class.new }
    let(:bson) { NO_VALUE }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"

    describe "#==" do
      context "when the objects are equal" do
        let(:other) { described_class.new }

        it "returns true" do
          expect(subject).to eq(other)
        end
      end

      context "when the other object is not a max_key" do
        it "returns false" do
          expect(subject).to_not eq("test")
        end
      end
    end

    describe "#>" do
      it "always returns true" do
        expect(subject > Integer::MAX_64BIT).to be_true
      end
    end

    describe "#<" do
      it "always returns false" do
        expect(subject < Integer::MAX_64BIT).to be_false
      end
    end
  end
end
