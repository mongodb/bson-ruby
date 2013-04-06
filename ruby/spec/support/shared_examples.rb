# encoding: utf-8
shared_examples_for "a binary encoded string" do

  let(:binary_encoding) do
    Encoding.find(BSON::BINARY)
  end

  unless RUBY_VERSION < "1.9"
    it "returns the string with binary encoding" do
      expect(encoded.encoding).to eq(binary_encoding)
    end
  end
end

shared_examples_for "a bson element" do

  let(:element) do
    defined?(obj) ? obj : described_class.new
  end

  it "has the correct single byte BSON type" do
    expect(element.bson_type).to eq(type)
  end
end

shared_examples_for "a serializable bson element" do

  it "serializes to bson" do
    expect(obj.to_bson).to eq(bson)
  end

  it "serializes to bson by appending" do
    expect(obj.to_bson('previous_content')).to eq('previous_content' << bson)
  end
end

shared_examples_for "a deserializable bson element" do

  let(:io) do
    StringIO.new(bson)
  end

  it "deserializes from bson" do
    expect(described_class.from_bson(io)).to eq(obj)
  end
end

shared_examples_for "a JSON serializable object" do

  it "serializes the JSON from #as_json" do
    expect(object.to_json).to eq(object.as_json.to_json)
  end
end

shared_examples_for "immutable when frozen" do |block|

  context "when the document is frozen" do

    before do
      doc.freeze
    end

    it "raises a runtime error" do
      expect {
        block.call(doc)
      }.to raise_error(RuntimeError)
    end
  end
end

shared_examples_for "a document able to handle utf-8" do

  it "serializes and deserializes properly" do
    expect(
      BSON::Document.from_bson(StringIO.new(document.to_bson))
    ).to eq(document)
  end
end
