require "spec_helper"

describe BSON::Ext::Time do

  describe "::BSON_TYPE" do

    it "returns 0x09" do
      expect(Time::BSON_TYPE).to eq(9.chr)
    end
  end

  describe "#bson_type" do

    let(:time) do
      Time.now
    end

    it "returns the BSON_TYPE" do
      expect(time.bson_type).to eq(Time::BSON_TYPE)
    end
  end

  describe "#to_bson" do

    context "when the time is post epoch" do

      let(:time) do
        Time.new(2012, 1, 1, 0, 0, 0)
      end

      let(:encoded) do
        time.to_bson
      end

      let(:expected) do
        (time.to_f * 1000).to_i.to_bson
      end

      it "returns the encoded string" do
        expect(encoded).to eq(expected)
      end
    end

    context "when the time is pre epoch" do

      let(:time) do
        Time.new(1969, 1, 1, 0, 0, 0)
      end

      let(:encoded) do
        time.to_bson
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
