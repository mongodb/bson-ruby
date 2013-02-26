require "spec_helper"

describe BSON::Ext::Date do

  describe "#bson_type" do

    let(:date) do
      Date.new(2013, 2, 1)
    end

    it "returns the BSON_TYPE" do
      expect(date.bson_type).to eq(Time::BSON_TYPE)
    end
  end

  describe "#to_bson" do

    context "when the date is post epoch" do

      let(:date) do
        Date.new(2012, 1, 1)
      end

      let(:time) do
        Time.new(2012, 1, 1, 0, 0, 0)
      end

      let(:encoded) do
        date.to_bson
      end

      let(:expected) do
        (time.to_f * 1000).to_i.to_bson
      end

      it "returns the encoded string" do
        expect(encoded).to eq(expected)
      end
    end

    context "when the date is pre epoch" do

      let(:date) do
        Date.new(1969, 1, 1)
      end

      let(:time) do
        Time.new(1969, 1, 1, 0, 0, 0)
      end

      let(:encoded) do
        date.to_bson
      end

      let(:expected) do
        (time.to_f * 1000).to_i.to_bson
      end

      it "returns the encoded string" do
        expect(encoded).to eq(expected)
      end
    end
  end
end
