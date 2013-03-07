# encoding: utf-8
require "spec_helper"

module BSON
  describe Int64 do
    let(:type) { 18.chr }
    let(:obj)  { 12332423432242 }
    let(:bson) { [ obj ].pack(Int64::PACK) }

    it_behaves_like "a bson element"
    it_behaves_like "a deserializable bson element"
  end
end
