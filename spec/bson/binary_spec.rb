# Copyright (C) 2009-2013 MongoDB Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "spec_helper"

describe BSON::Binary do

  describe "#as_json" do

    let(:object) do
      described_class.new("testing", :user)
    end

    it "returns the binary data plus type" do
      expect(object.as_json).to eq(
        { "$binary" => "testing", "$type" => :user }
      )
    end

    it_behaves_like "a JSON serializable object"
  end

  describe "#initialize" do

    context "when he type is invalid" do

      it "raises an error" do
        expect {
          described_class.new("testing", :error)
        }.to raise_error { |error|
          error.should be_a(BSON::Binary::InvalidType)
          error.message.should match /is not a valid binary type/
        }
      end
    end
  end

  describe "#to_bson/#from_bson" do

    let(:type) { 5.chr }

    it_behaves_like "a bson element"

    context "when the type is :generic" do

      let(:obj)  { described_class.new("testing") }
      let(:bson) { "#{7.to_bson}#{0.chr}testing" }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :function" do

      let(:obj)  { described_class.new("testing", :function) }
      let(:bson) { "#{7.to_bson}#{1.chr}testing" }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :old" do

      let(:obj)  { described_class.new("testing", :old) }
      let(:bson) { "#{11.to_bson}#{2.chr}#{7.to_bson}testing" }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :uuid_old" do

      let(:obj)  { described_class.new("testing", :uuid_old) }
      let(:bson) { "#{7.to_bson}#{3.chr}testing" }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :uuid" do

      let(:obj)  { described_class.new("testing", :uuid) }
      let(:bson) { "#{7.to_bson}#{4.chr}testing" }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :md5" do

      let(:obj)  { described_class.new("testing", :md5) }
      let(:bson) { "#{7.to_bson}#{5.chr}testing" }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end

    context "when the type is :user" do

      let(:obj)  { described_class.new("testing", :user) }
      let(:bson) { "#{7.to_bson}#{128.chr}testing" }

      it_behaves_like "a serializable bson element"
      it_behaves_like "a deserializable bson element"
    end
  end
end
