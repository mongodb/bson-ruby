# encoding: utf-8
require "spec_helper"

describe String do

  describe "#to_bson/#from_bson" do

    let(:type) { 2.chr }
    let(:obj) { "test" }
    let(:bson) { "#{5.to_bson}test#{BSON::NULL_BYTE}" }

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"
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

      it "appends to optional previous content" do
        expect(string.to_bson_cstring('previous_content')).to eq('previous_content' << encoded)
      end
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
        "ß".chr.force_encoding(BSON::BINARY)
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
        "ß".chr.force_encoding(BSON::BINARY)
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

      it "appends to optional previous content" do
        expect(string.to_bson_string('previous_content')).to eq('previous_content' << encoded)
      end

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
        "ß".chr.force_encoding(BSON::BINARY)
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
        "ß".chr.force_encoding(BSON::BINARY)
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
