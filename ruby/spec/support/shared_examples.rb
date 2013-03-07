# encoding: utf-8

module BSON
  shared_examples_for "a binary encoded string" do
    let(:binary_encoding) do
      Encoding.find(BSON::BINARY)
    end

    it "returns the string with binary encoding" do
      expect(encoded.encoding).to eq(binary_encoding)
    end
  end

  shared_examples_for 'a bson element' do
    subject { (defined? obj) ? obj : described_class.new  }
    its(:bson_type) { should eq(type) }
  end

  shared_examples_for 'a serializable bson element' do
    it 'serializes to bson' do
      obj.to_bson.should == bson
    end
  end

  shared_examples_for 'a deserializable bson element' do
    it 'deserializes from bson' do
      io = StringIO.new(bson)
      described_class.from_bson(io).should == obj
    end
  end
end

shared_examples_for "a JSON serializable object" do

  it "serializes the JSON from #as_json" do
    expect(object.to_json).to eq(object.as_json.to_json)
  end
end
