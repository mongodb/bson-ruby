# encoding: utf-8
require "spec_helper"

# Note that hash specific specs are based off the rubyspec library, and
# converted manually to RSpec syntax.
#
# @see https://github.com/rubyspec/rubyspec/tree/master/core/hash
describe BSON::Document do

  pending "#=="
  pending "#[]"
  pending "#[]"
  pending "#[]="

  describe "#allocate" do

    let(:doc) do
      described_class.allocate
    end

    it "returns an instance of a Document" do
      expect(doc).to be_a(described_class)
    end

    it "returns a fully-formed instance of a Document" do
      expect(doc.size).to eq(0)
    end
  end

  describe "#assoc" do

    let(:doc) do
      { :apple => :green, :orange => :orange, :grape => :green, :banana => :yellow }
    end

    it "returns an Array if the argument is == to a key of the Hash" do
      expect(doc.assoc(:apple)).to be_a(Array)
    end

    it "returns a 2-element Array if the argument is == to a key of the Hash" do
      expect(doc.assoc(:grape).size).to eq(2)
    end

    it "sets the first element of the Array to the located key" do
      expect(doc.assoc(:banana).first).to eq(:banana)
    end

    it "sets the last element of the Array to the value of the located key" do
      expect(doc.assoc(:banana).last).to eq(:yellow)
    end

    it "uses #== to compare the argument to the keys" do
      doc[1.0] = :value
      expect(doc.assoc(1)).to eq([ 1.0, :value ])
    end

    it "returns nil if the argument is not a key of the Hash" do
      expect(doc.assoc(:green)).to be_nil
    end

    context "when the document compares by identity" do

      before do
        doc.compare_by_identity
        doc["pear"] = :red
        doc["pear"] = :green
      end

      it "duplicates keys" do
        expect(doc.keys.grep(/pear/).size).to eq(2)
      end

      it "only returns the first matching key-value pair" do
        expect(doc.assoc("pear")).to eq([ "pear", :red ])
      end
    end

    context "when there is a default value" do

      context "when specified in the constructor" do

        let(:doc) do
          described_class.new(42).merge!(:foo => :bar)
        end

        context "when the argument is not a key" do

          it "returns nil" do
            expect(doc.assoc(42)).to be_nil
          end
        end
      end

      context "when specified by a block" do

        let(:doc) do
          described_class.new{|h, k| h[k] = 42}.merge!(:foo => :bar)
        end

        context "when the argument is not a key" do

          it "returns nil" do
            expect(doc.assoc(42)).to be_nil
          end
        end
      end
    end
  end

  describe "#clear" do

    let(:doc) do
      described_class[1 => 2, 3 => 4]
    end

    it "removes all key, value pairs" do
      expect(doc.clear).to be_empty
    end

    it "returns the same instance" do
      expect(doc.clear).to eql(doc)
    end

    context "when the document has a default" do

      context "when the default is a value" do

        let(:doc) do
          described_class.new(5)
        end

        before do
          doc.clear
        end

        it "keeps the default value" do
          expect(doc.default).to eq(5)
        end

        it "returns the default for empty keys" do
          expect(doc["z"]).to eq(5)
        end
      end

      context "when the default is a proc" do

        let(:doc) do
          described_class.new { 5 }
        end

        before do
          doc.clear
        end

        it "keeps the default proc" do
          expect(doc.default_proc).to_not be_nil
        end

        it "returns the default for empty keys" do
          expect(doc["z"]).to eq(5)
        end
      end
    end

    context "when the document is frozen" do

      before do
        doc.freeze
      end

      it "raises an error" do
        expect {
          doc.clear
        }.to raise_error(RuntimeError)
      end
    end
  end

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
