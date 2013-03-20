# encoding: utf-8
require "spec_helper"

describe BSON::Document do

  pending "#=="
  pending "#[]"
  pending "#[]"
  pending "#[]="

  describe "#allocate" do

    let(:document) do
      described_class.allocate
    end

    it "returns an instance of a Document" do
      expect(document).to be_a(described_class)
    end

    it "returns a fully-formed instance of a Document" do
      expect(document.size).to eq(0)
    end
  end

  pending "#assoc"
  pending "#clear"
  pending "#compare_by_identity"
  pending "#compare_by_identity?"
  pending "#default"
  pending "#default="
  pending "#default_proc"
  pending "#default_proc="
  pending "#delete"
  pending "#delete_if"
  pending "#each"
  pending "#each_key"
  pending "#each_pair"
  pending "#each_value"
  pending "#empty?"
  pending "#eql?"
  pending "#fetch"
  pending "#flatten"
  pending "#has_key?"
  pending "#has_value?"
  pending "#hash"
  pending "#include?"
  pending "#initialize_copy"
  pending "#inspect"
  pending "#invert"
  pending "#keep_if"
  pending "#key"
  pending "#key?"
  pending "#keys"
  pending "#length"
  pending "#member?"
  pending "#merge"
  pending "#merge!"
  pending "#new"
  pending "#pretty_print"
  pending "#pretty_print_cycle"
  pending "#rassoc"
  pending "#rehash"
  pending "#reject"
  pending "#reject!"
  pending "#replace"
  pending "#select"
  pending "#select!"
  pending "#shift"
  pending "#size"
  pending "#store"
  pending "#to_a"
  pending "#to_hash"
  pending "#to_s"
  pending "#try_convert"
  pending "#update"
  pending "#value?"
  pending "#values"
  pending "#values_at"

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
      it_behaves_like "a deserializable bson element"
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
      it_behaves_like "a deserializable bson element"
    end
  end
end
