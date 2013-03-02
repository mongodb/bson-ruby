# encoding: utf-8
require "spec_helper"

describe BSON::Element do

  describe "#initialize" do

    let(:element) do
      described_class.new("name", "value")
    end

    it "sets the field" do
      expect(element.field).to eq("name")
    end

    it "sets the value" do
      expect(element.value).to eq("value")
    end
  end

  describe "#to_bson" do

    context "when the field is a string" do

      let(:element) do
        described_class.new("name", "value")
      end

      let(:encoded) do
        element.to_bson
      end

      it "encodes the type + field + value" do
        expect(encoded).to eq(
          "#{String::BSON_TYPE}#{"name".to_bson_cstring}#{"value".to_bson}"
        )
      end
    end

    context "when the field is a symbol" do

      let(:element) do
        described_class.new(:name, "value")
      end

      let(:encoded) do
        element.to_bson
      end

      it "encodes the type + field + value" do
        expect(encoded).to eq(
          "#{String::BSON_TYPE}#{"name".to_bson_cstring}#{"value".to_bson}"
        )
      end
    end
  end
end
