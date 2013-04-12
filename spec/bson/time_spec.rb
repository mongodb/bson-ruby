# encoding: utf-8
require "spec_helper"

describe Time do

  describe "#to_bson/#from_bson" do

    let(:type) { 9.chr }

    it_behaves_like "a bson element"

    context "when the time is post epoch" do

      let(:obj)  { Time.utc(2012, 1, 1, 0, 0, 0) }
      let(:bson) { [ (obj.to_f * 1000).to_i ].pack(BSON::Int64::PACK) }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the time is pre epoch" do

      let(:obj)  { Time.utc(1969, 1, 1, 0, 0, 0) }
      let(:bson) { [ (obj.to_f * 1000).to_i ].pack(BSON::Int64::PACK) }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end
  end
end
