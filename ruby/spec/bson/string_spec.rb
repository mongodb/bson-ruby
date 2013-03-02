# encoding: utf-8
require "spec_helper"

describe BSON::String do

  shared_examples_for "a binary encoded string" do

    let(:binary) do
      Encoding.find(BSON::String::BINARY)
    end

    it "returns the string with binary encoding" do
      expect(encoded.encoding).to eq(binary)
    end
  end

  describe "::BSON_TYPE" do

    it "returns 0x02" do
      expect(String::BSON_TYPE).to eq(2.chr)
    end
  end

  describe "#bson_type" do

    it "returns the BSON_TYPE" do
      expect("test".bson_type).to eq(String::BSON_TYPE)
    end
  end

  describe "#to_bson" do

    let(:string) do
      "test"
    end

    let(:encoded) do
      string.to_bson
    end

    it "returns the encoded string" do
      expect(encoded).to eq("#{5.to_bson}test#{BSON::NULL_BYTE}")
    end
  end

  describe "#to_bson_cstring" do

    context "when the string is valid" do

      let(:string) do
        "test"
      end

      let(:encoded) do
        string.to_bson_cstring
      end

      it "returns the encoded string" do
        expect(encoded).to eq("test#{BSON::NULL_BYTE}")
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the string contains a null byte" do

      let(:string) do
        "test#{BSON::NULL_BYTE}ing"
      end

      it "raises an error" do
        expect {
          string.to_bson_cstring
        }.to raise_error(EncodingError)
      end
    end

    context "when the string contains utf-8 characters" do

      let(:string) do
        "Straße"
      end

      let(:encoded) do
        string.to_bson_cstring
      end

      let(:char) do
        "ß".chr.force_encoding(BSON::String::BINARY)
      end

      it "returns the encoded string" do
        expect(encoded).to eq("Stra#{char}e#{BSON::NULL_BYTE}")
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the string is encoded in non utf-8" do

      let(:string) do
        "Straße".encode("iso-8859-1")
      end

      let(:encoded) do
        string.to_bson_cstring
      end

      let(:char) do
        "ß".chr.force_encoding(BSON::String::BINARY)
      end

      it "returns the encoded string" do
        expect(encoded).to eq("Stra#{char}e#{BSON::NULL_BYTE}")
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the string contains non utf-8 characters" do

      let(:string) do
        255.chr
      end

      it "raises an error" do
        expect {
          string.to_bson_cstring
        }.to raise_error(EncodingError)
      end
    end
  end

  describe "#to_bson_string" do

    context "when the string is valid" do

      let(:string) do
        "test"
      end

      let(:encoded) do
        string.to_bson_string
      end

      it "returns the string" do
        expect(encoded).to eq(string)
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the string contains a null byte" do

      let(:string) do
        "test#{BSON::NULL_BYTE}ing"
      end

      let(:encoded) do
        string.to_bson_string
      end

      it "retains the null byte" do
        expect(encoded).to eq(string)
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the string contains utf-8 characters" do

      let(:string) do
        "Straße"
      end

      let(:encoded) do
        string.to_bson_string
      end

      let(:char) do
        "ß".chr.force_encoding(BSON::String::BINARY)
      end

      it "returns the encoded string" do
        expect(encoded).to eq("Stra#{char}e")
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the string is encoded in non utf-8" do

      let(:string) do
        "Straße".encode("iso-8859-1")
      end

      let(:encoded) do
        string.to_bson_string
      end

      let(:char) do
        "ß".chr.force_encoding(BSON::String::BINARY)
      end

      it "returns the encoded string" do
        expect(encoded).to eq("Stra#{char}e")
      end

      it_behaves_like "a binary encoded string"
    end

    context "when the string contains non utf-8 characters" do

      let(:string) do
        255.chr
      end

      it "raises an error" do
        expect {
          string.to_bson_string
        }.to raise_error(EncodingError)
      end
    end
  end

  context "when the class is loaded" do

    let(:registered) do
      BSON::Registry.get(String::BSON_TYPE)
    end

    it "registers the type" do
      expect(registered).to eq(String)
    end
  end
end
