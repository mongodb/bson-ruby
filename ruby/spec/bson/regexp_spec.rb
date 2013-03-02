# encoding: utf-8
require "spec_helper"

describe BSON::Regexp do

  describe "::BSON_TYPE" do

    it "returns 0x0B" do
      expect(Regexp::BSON_TYPE).to eq(11.chr)
    end
  end

  describe "#bson_type" do

    it "returns the BSON_TYPE" do
      expect(%r{\d+}.bson_type).to eq(Regexp::BSON_TYPE)
    end
  end

  describe "#to_bson" do

    context "when the regexp has no options" do

      let(:regexp) do
        /\d+/
      end

      let(:encoded) do
        regexp.to_bson
      end

      let(:expected) do
        "#{regexp.source}#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}"
      end

      it "returns the encoded string" do
        expect(encoded).to eq(expected)
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the regexp has options" do

      context "when ignoring case" do

        let(:regexp) do
          /\W+/i
        end

        let(:encoded) do
          regexp.to_bson
        end

        let(:expected) do
          "#{regexp.source}#{BSON::NULL_BYTE}i#{BSON::NULL_BYTE}"
        end

        it "adds the encoding option" do
          expect(encoded).to eq(expected)
        end

        it_behaves_like "a binary encoded string"
      end

      context "when matching multiline" do

        let(:regexp) do
          /\W+/m
        end

        let(:encoded) do
          regexp.to_bson
        end

        let(:expected) do
          "#{regexp.source}#{BSON::NULL_BYTE}ms#{BSON::NULL_BYTE}"
        end

        it "adds the encoding option" do
          expect(encoded).to eq(expected)
        end

        it_behaves_like "a binary encoded string"
      end

      context "when matching extended" do

        let(:regexp) do
          /\W+/x
        end

        let(:encoded) do
          regexp.to_bson
        end

        let(:expected) do
          "#{regexp.source}#{BSON::NULL_BYTE}x#{BSON::NULL_BYTE}"
        end

        it "adds the encoding option" do
          expect(encoded).to eq(expected)
        end

        it_behaves_like "a binary encoded string"
      end

      context "when all options are present" do

        let(:regexp) do
          /\W+/xim
        end

        let(:encoded) do
          regexp.to_bson
        end

        let(:expected) do
          "#{regexp.source}#{BSON::NULL_BYTE}imsx#{BSON::NULL_BYTE}"
        end

        it "adds the encoding options in alphabetical order" do
          expect(encoded).to eq(expected)
        end

        it_behaves_like "a binary encoded string"
      end
    end
  end

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(Regexp::BSON_TYPE)
    end

    it "registers the type" do
      expect(registered).to eq(Regexp)
    end
  end
end
