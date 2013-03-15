# encoding: utf-8
shared_examples_for "a binary encoded string" do

  let(:binary_encoding) do
    Encoding.find(BSON::BINARY)
  end

  it "returns the string with binary encoding" do
    expect(encoded.encoding).to eq(binary_encoding)
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
