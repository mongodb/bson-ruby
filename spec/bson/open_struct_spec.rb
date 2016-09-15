# Copyright (C) 2016 MongoDB Inc.
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

describe OpenStruct do

  describe "#to_bson" do

    let(:type) { 3.chr }

    it_behaves_like "a bson element"

    context "when the struct is a single level" do

      let(:obj) do
        described_class.new({"key" => "value" })
      end

      let(:bson) do
        "#{20.to_bson.to_s}#{String::BSON_TYPE}key#{BSON::NULL_BYTE}" +
        "#{6.to_bson.to_s}value#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}"
      end

      it_behaves_like "a serializable bson element"
    end

    context "when the struct has invalid keys" do

      let(:obj) do
        described_class.new({ "$testing" => "value" })
      end

      context "when validating keys" do

        context "when validating globally" do

          before do
            BSON::Config.validating_keys = true
          end

          after do
            BSON::Config.validating_keys = false
          end

          it "raises an error" do
            expect {
              obj.to_bson
            }.to raise_error(BSON::String::IllegalKey)
          end

          context "when the struct contains an array of documents containing invalid keys" do

            let(:obj) do
              described_class.new({ "array" =>  [{ "$testing" => "value" }] })
            end

            it "raises an error" do
              expect {
                obj.to_bson
              }.to raise_error(BSON::String::IllegalKey)
            end
          end
        end

        context "when validating locally" do

          it "raises an error" do
            expect {
              obj.to_bson(BSON::ByteBuffer.new, true)
            }.to raise_error(BSON::String::IllegalKey)
          end

          context "when the struct contains an array of documents containing invalid keys" do

            let(:obj) do
              described_class.new({ "array" =>  [{ "$testing" => "value" }] })
            end

            it "raises an error" do
              expect {
                obj.to_bson(BSON::ByteBuffer.new, true)
              }.to raise_error(BSON::String::IllegalKey)
            end
          end
        end
      end

      context "when not validating keys" do

        let(:bson) do
          "#{25.to_bson.to_s}#{String::BSON_TYPE}$testing#{BSON::NULL_BYTE}" +
          "#{6.to_bson.to_s}value#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}"
        end

        it "serializes the struct" do
          expect(obj.to_bson.to_s).to eq(bson)
        end

        context "when the struct contains an array of documents containing invalid keys" do

          let(:obj) do
            described_class.new({ "array" =>  [{ "$testing" => "value" }] })
          end

          let(:bson) do
            "#{45.to_bson.to_s}#{Array::BSON_TYPE}array#{BSON::NULL_BYTE}" +
              "#{[{ "$testing" => "value" }].to_bson.to_s}#{BSON::NULL_BYTE}"
          end

          it "serializes the struct" do
            expect(obj.to_bson.to_s).to eq(bson)
          end
        end
      end
    end

    context "when the struct is embedded" do

      let(:obj) do
        described_class.new({ "field" => OpenStruct.new({ "key" => "value" })})
      end

      let(:bson) do
        "#{32.to_bson.to_s}#{Hash::BSON_TYPE}field#{BSON::NULL_BYTE}" +
        "#{20.to_bson.to_s}#{String::BSON_TYPE}key#{BSON::NULL_BYTE}" +
        "#{6.to_bson.to_s}value#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}#{BSON::NULL_BYTE}"
      end

      it_behaves_like "a serializable bson element"
    end
  end
end
