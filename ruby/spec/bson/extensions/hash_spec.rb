require 'spec_helper'

module BSON
  describe Hash do
    let(:type) { "\x03" }
    let(:obj)  { {:a => "b"} }
    let(:value) { "\x0E\x00\x00\x00\x02a\x00\x02\x00\x00\x00b\x00\x00" }

    it_behaves_like 'a bson element'
  end
end