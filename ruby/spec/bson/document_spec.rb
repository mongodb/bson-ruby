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

        let(:doc) { described_class.new(42).merge!(:foo => :bar) }

        context "when the argument is not a key" do

          it "returns nil" do
            expect(doc.assoc(42)).to be_nil
          end
        end
      end

      context "when specified by a block" do

        let(:doc) { described_class.new{|h, k| h[k] = 42}.merge!(:foo => :bar) }

        context "when the argument is not a key" do

          it "returns nil" do
            expect(doc.assoc(42)).to be_nil
          end
        end
      end
    end
  end

  describe "#clear" do

    let(:doc) { described_class[1 => 2, 3 => 4] }

    it "removes all key, value pairs" do
      expect(doc.clear).to be_empty
    end

    it "returns the same instance" do
      expect(doc.clear).to eql(doc)
    end

    context "when the document has a default" do

      context "when the default is a value" do

        let(:doc) { described_class.new(5) }

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

        let(:doc) { described_class.new { 5 } }

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

    it_behaves_like "immutable when frozen", ->(doc){ doc.clear }
  end

  describe "#compare_by_identity" do

    let(:doc) { described_class.new }
    let!(:identity) { doc.compare_by_identity }

    it "causes future comparisons on the receiver to be made by identity" do
      doc["a"] = :a
      expect(doc["a"]).to be_nil
    end

    it "causes #compare_by_identity? to return true" do
      expect(doc).to be_compare_by_identity
    end

    it "returns self" do
      expect(identity).to eql(doc)
    end

    it "uses the semantics of BasicObject#equal? to determine key identity" do
      doc[-0.0] = :a
      doc[-0.0] = :b
      doc[[ 1 ]] = :c
      doc[[ 1 ]] = :d
      doc[:bar] = :e
      doc[:bar] = :f
      doc["bar"] = :g
      doc["bar"] = :h
      expect(doc.values).to eq([ :a, :b, :c, :d, :f, :g, :h ])
    end

    it "uses #equal? semantics, but doesn't actually call #equal? to determine identity" do
      obj = mock("equal")
      obj.should_not_receive(:equal?)
      doc[:foo] = :glark
      doc[obj] = :a
      expect(doc[obj]).to eq(:a)
    end

    it "regards #dup'd objects as having different identities" do
      str = "foo"
      doc[str.dup] = :str
      expect(doc[str]).to be_nil
    end

    it "regards #clone'd objects as having different identities" do
      str = 'foo'
      doc[str.clone] = :str
      expect(doc[str]).to be_nil
    end

    it "regards references to the same object as having the same identity" do
      o = Object.new
      doc[o] = :o
      doc[:a] = :a
      expect(doc[o]).to eq(:o)
    end

    it "perists over #dups" do
      doc["foo"] = :bar
      doc["foo"] = :glark
      expect(doc.dup).to eq(doc)
      expect(doc.dup.size).to eq(doc.size)
    end

    it "persists over #clones" do
      doc["foo"] = :bar
      doc["foo"] = :glark
      expect(doc.clone).to eq(doc)
      expect(doc.clone.size).to eq(doc.size)
    end

    it_behaves_like "immutable when frozen", ->(doc){ doc.compare_by_identity }
  end

  describe "#compare_by_identity?" do

    let(:doc) { described_class.new }

    context "when the document is comparing by identity" do

      before do
        doc.compare_by_identity
      end

      it "returns true" do
        expect(doc).to be_compare_by_identity
      end
    end

    context "when the document is not comparing by identity" do

      it "returns false" do
        expect(doc).to_not be_compare_by_identity
      end
    end
  end

  describe "#default" do

    context "when provided a value" do

      let(:doc) { described_class.new(5) }

      context "when provided no args" do

        it "returns the default" do
          expect(doc.default).to eq(5)
        end
      end

      context "when provided args" do

        it "returns the default" do
          expect(doc.default(4)).to eq(5)
        end
      end
    end

    context "when provided a proc" do

      let(:doc) do
        described_class.new { |*args| args }
      end

      it "uses the default proc to compute a default value" do
        expect(doc.default(5)).to eq([ doc, 5 ])
      end

      context "when no value is provided" do

        it "calls default proc with nil arg" do
          expect(doc.default).to be_nil
        end
      end
    end
  end

  describe "#default=" do

    let(:doc) { described_class.new }

    it "sets the default value" do
      doc.default = 99
      expect(doc.default).to eq(99)
    end

    context "when a deafult proc exists" do

      let(:doc) do
        described_class.new { 6 }
      end

      it "unsets the default proc" do
        doc.default = 50
        expect(doc.default_proc).to be_nil
      end
    end

    it_behaves_like "immutable when frozen", ->(doc){ doc.default = 1 }
  end

  pending "#default_proc"
  pending "#default_proc="

  describe "#delete" do

    let(:doc) { described_class[:a => 5, :b => 2] }

    it "removes the entry" do
      doc.delete(:b)
      expect(doc).to eq(described_class[:a => 5 ])
    end

    it "returns the deleted value" do
      expect(doc.delete(:b)).to eq(2)
    end

    context "when the key is not found" do

      context "when a block is provided" do

        it "calls the block" do
          expect(doc.delete(:d){ 5 }).to eq(5)
        end
      end

      context "when no block is provided" do

        it "returns nil" do
          expect(doc.delete(:d)).to be_nil
        end
      end
    end

    it_behaves_like "immutable when frozen", ->(doc){ doc.delete(1) }
  end

  describe "#delete_if" do

    let(:doc) { described_class[1 => 2, 3 => 4] }

    it "yields a key and value" do
      all_args = []
      doc.delete_if{ |*args| all_args << args }
      expect(all_args.sort).to eq([[ 1, 2 ], [ 3, 4 ]])
    end

    it "removes all entries for which the block is true" do
      expect(doc.delete_if{ |k, v| k < 2 }).to eq({ 3 => 4 })
    end

    it "returns self" do
      expect(doc.delete_if{ |k, v| k < 2 }).to equal(doc)
    end

    it "processes entries in the same order as each" do
      each_pairs = []
      delete_pairs = []

      doc.each_pair{ |k, v| each_pairs << [ k, v ]}
      doc.delete_if{ |k, v| delete_pairs << [ k,v ]}

      expect(each_pairs).to eq(delete_pairs)
    end

    it_behaves_like "immutable when frozen", ->(doc){ doc.delete_if{} }
  end

  pending "#each"

  describe "#each_key" do

    let(:doc) { described_class[1 => -1, 2 => -2, 3 => -3, 4 => -4] }

    it "calls block once for each key, passing key" do
      keys = []
      doc.each_key { |k| keys << k }
      expect(keys).to eq([ 1, 2, 3, 4 ])
    end

    it "returns the document" do
      expect(doc.each_key { |k| k }).to equal(doc)
    end

    it "processes keys in the same order as keys()" do
      keys = []
      doc.each_key { |k| keys << k }
      expect(keys).to eq(doc.keys)
    end
  end

  describe "#each_pair" do

    let(:all_args) {[]}
    let(:doc) { described_class[1 => 2, 3 => 4] }

    context "when the block expects |key, value|" do

      let!(:iterated) do
        doc.each_pair{ |key, value| all_args << [ key, value ] }
      end

      it "yields the key and value" do
        expect(all_args.sort).to eq([[1, 2], [3, 4]])
      end

      it "returns the document" do
        expect(iterated).to equal(doc)
      end
    end

    context "when the block expects |args|" do

      let!(:iterated) do
        doc.each_pair{ |args| p args; all_args << args }
      end

      it "yields a [key, value]" do
        expect(all_args.sort).to eq([[1, 2], [3, 4]])
      end

      it "returns the document" do
        expect(iterated).to equal(doc)
      end
    end
  end

  describe "#each_value" do

    let(:values) {[]}
    let(:doc) do
      described_class[:a => -5, :b => -3, :c => -2, :d => -1, :e => -1]
    end
    let!(:iterated) do
      doc.each_value{ |v| values << v }
    end

    it "calls block once for each key, passing value" do
      expect(values.sort).to eq([-5, -3, -2, -1, -1])
    end

    it "processes values in the same order as values()" do
      expect(values).to eq(doc.values)
    end

    it "returns the document" do
      expect(iterated).to equal(doc)
    end
  end

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
