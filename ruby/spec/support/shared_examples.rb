# encoding: utf-8
shared_examples_for "a binary encoded string" do

  let(:binary_encoding) do
    Encoding.find(BSON::BINARY)
  end

  it "returns the string with binary encoding" do
    expect(encoded.encoding).to eq(binary_encoding)
  end
end
