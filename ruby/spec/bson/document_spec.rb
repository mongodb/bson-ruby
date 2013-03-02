# encoding: utf-8
require "spec_helper"

describe BSON::Document do

  describe ".serialize" do

    context "when provided a hash" do

      context "when the hash is all valid types" do

        let(:document) do
          { "key" => "value" }
        end

        let(:serialized) do
          described_class.serialize(document)
        end

        it "serializes the document" do
          expect(serialized).to eq(
            "#{20.to_bson}#{String::BSON_TYPE}key#{BSON::NULL_BYTE}" +
            "#{6.to_bson}value#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}"
          )
        end
      end
    end
  end
end
