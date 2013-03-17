# encoding: utf-8
require "spec_helper"

describe BSON::Document do

  describe "#to_bson/#from_bson" do

    let(:type) { 3.chr }

    it_behaves_like "a bson element"

    context "when the hash is a single level" do

      let(:obj) do
        described_class["key" => "value"]
      end

      let(:bson) do
        "#{20.to_bson}#{String::BSON_TYPE}key#{BSON::NULL_BYTE}" +
        "#{6.to_bson}value#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}"
      end

      it_behaves_like "a serializable bson element"
      pending do
        it_behaves_like "a deserializable bson element"
      end
    end

    context "when the hash is embedded" do

      let(:obj) do
        described_class["field" => { "key" => "value" }]
      end

      let(:bson) do
        "#{32.to_bson}#{Hash::BSON_TYPE}field#{BSON::NULL_BYTE}" +
        "#{20.to_bson}#{String::BSON_TYPE}key#{BSON::NULL_BYTE}" +
        "#{6.to_bson}value#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}"
      end

      it_behaves_like "a serializable bson element"
      pending do
        it_behaves_like "a deserializable bson element"
      end
    end
  end
end
