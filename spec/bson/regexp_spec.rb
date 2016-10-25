# Copyright (C) 2009-2014 MongoDB Inc.
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

describe Regexp do

  describe "#as_json" do

    let(:object) do
      /\W+/i
    end

    it "returns the binary data plus type" do
      expect(object.as_json).to eq(
        { "$regex" => "\\W+", "$options" => "im" }
      )
    end

    it_behaves_like "a JSON serializable object"
  end

  describe "#to_bson/#from_bson" do

    let(:type) { 11.chr }
    let(:obj)  { /test/ }

    let(:io) do
      BSON::ByteBuffer.new(bson)
    end

    let(:regex) do
      described_class.from_bson(io)
    end

    let(:result) do
      regex.compile
    end

    it_behaves_like "a bson element"

    context "when calling normal regexp methods on a Regexp::Raw" do
      let :obj do
        /\d+/
      end

      let(:bson) { "#{obj.source}#{BSON::NULL_BYTE}m#{BSON::NULL_BYTE}" }

      it_behaves_like "a serializable bson element"

      it "runs the method on the Regexp object" do
        expect(regex.match('6')).not_to be_nil
      end
    end

    context "when the regexp has no options" do

      let(:obj)  { /\d+/ }
      # Ruby always has a BSON regex's equivalent of multiline on
      # http://www.regular-expressions.info/modifiers.html
      let(:bson) { "#{obj.source}#{BSON::NULL_BYTE}m#{BSON::NULL_BYTE}" }

      it_behaves_like "a serializable bson element"

      it "deserializes from bson" do
        expect(result).to eq(obj)
      end
    end

    context "when the regexp has options" do

      context "when ignoring case" do

        let(:obj)  { /\W+/i }
        let(:bson) { "#{obj.source}#{BSON::NULL_BYTE}im#{BSON::NULL_BYTE}" }

        it_behaves_like "a serializable bson element"

        it "deserializes from bson" do
          expect(result).to eq(obj)
        end
      end

      context "when matching multiline" do

        let(:obj)  { /\W+/m }
        let(:bson) { "#{obj.source}#{BSON::NULL_BYTE}ms#{BSON::NULL_BYTE}" }

        it_behaves_like "a serializable bson element"

        it "deserializes from bson" do
          expect(result).to eq(obj)
        end
      end

      context "when matching extended" do

        let(:obj)  { /\W+/x }
        let(:bson) { "#{obj.source}#{BSON::NULL_BYTE}mx#{BSON::NULL_BYTE}" }

        it_behaves_like "a serializable bson element"

        it "deserializes from bson" do
          expect(result).to eq(obj)
        end
      end

      context "when all options are present" do

        let(:obj)  { /\W+/xim }
        let(:bson) { "#{obj.source}#{BSON::NULL_BYTE}imsx#{BSON::NULL_BYTE}" }

        it_behaves_like "a serializable bson element"

        it "deserializes from bson" do
          expect(result).to eq(obj)
        end
      end
    end
  end
end
