# encoding: utf-8
require "spec_helper"

describe BSON::Code do

  describe "#as_json" do

    let(:object) do
      described_class.new("this.value = 5")
    end

    it "returns the binary data plus type" do
      expect(object.as_json).to eq({ "$code" => "this.value = 5" })
    end

    it_behaves_like "a JSON serializable object"
  end

  let(:type) { 13.chr }
  let(:obj)  { described_class.new("this.value = 5") }
  let(:bson) { "#{15.to_bson}this.value = 5#{BSON::NULL_BYTE}" }

  it_behaves_like "a bson element"
  it_behaves_like "a serializable bson element"
  it_behaves_like "a deserializable bson element"
end
