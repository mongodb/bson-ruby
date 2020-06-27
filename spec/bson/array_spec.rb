# Copyright (C) 2009-2020 MongoDB Inc.
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

describe Array do

  describe "#to_bson/#from_bson" do

    let(:type) { 4.chr }
    let(:obj)  {[ "one", "two" ]}
    let(:bson) do
      BSON::Document["0", "one", "1", "two"].to_bson.to_s
    end

    it_behaves_like "a bson element"
    it_behaves_like "a serializable bson element"
    it_behaves_like "a deserializable bson element"

    context "when the array has documents containing invalid keys" do

      let(:obj) do
        [ { "$testing" => "value" } ]
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
        end

        context "when validating locally" do

          it "raises an error" do
            expect {
              obj.to_bson(BSON::ByteBuffer.new, true)
            }.to raise_error(BSON::String::IllegalKey)
          end

          context "when serializing different types" do

            let(:obj) do
              [ BSON::Binary.new("testing", :generic),
                BSON::Code.new("this.value = 5"),
                BSON::CodeWithScope.new("this.value = val", "test"),
                Date.new(2012, 1, 1),
                Time.utc(2012, 1, 1),
                DateTime.new(2012, 1, 1, 0, 0, 0),
                false,
                1.2332,
                Integer::MAX_32BIT - 1,
                BSON::ObjectId.new,
                /\W+/i,
                'a string',
                :a_symbol,
                Time.utc(2012, 1, 1, 0, 0, 0),
                BSON::Timestamp.new(1, 10),
                true,
                { "$testing" => "value" }
              ]
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
          BSON::Document["0", { "$testing" => "value" }].to_bson.to_s
        end

        it "serializes the hash" do
          expect(obj.to_bson.to_s).to eq(bson)
        end

        context "when serializing different types" do

          let(:obj) do
            [ BSON::Binary.new("testing", :generic),
              BSON::Code.new("this.value = 5"),
              BSON::CodeWithScope.new("this.value = val", "test"),
              Date.new(2012, 1, 1),
              Time.utc(2012, 1, 1),
              DateTime.new(2012, 1, 1, 0, 0, 0),
              false,
              1.2332,
              Integer::MAX_32BIT - 1,
              BSON::ObjectId.new,
              /\W+/i,
              'a string',
              :a_symbol,
              Time.utc(2012, 1, 1, 0, 0, 0),
              BSON::Timestamp.new(1, 10),
              true,
              { "$testing" => "value" }
            ]
          end

          it "serializes the hash" do
            expect(obj.to_bson.length).to eq(252)
          end
        end
      end
    end

    context 'when array contains value of an unserializable class' do
      class ArraySpecUnserializableClass
      end

      let(:obj) do
        [ArraySpecUnserializableClass.new]
      end

      it 'raises UnserializableClass' do
        lambda do
          obj.to_bson
        end.should raise_error(BSON::Error::UnserializableClass,
          # C extension does not provide element position in the exception message.
          /(Array element at position 0|Value) does not define its BSON serialized type:.*ArraySpecUnserializableClass/)
      end
    end
  end

  describe "#to_bson_normalized_value" do

    let(:klass) { Class.new(Hash) }
    let(:obj)  {[ Foo.new ]}

    before(:each) { stub_const "Foo", klass }

    it "does not mutate the receiver" do
      obj.to_bson_normalized_value
      expect(obj.first.class).to eq(Foo)
    end
  end

  describe "#to_bson_object_id" do

    context "when the array has 12 elements" do

      let(:array) do
        [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 ]
      end

      let(:converted) do
        array.to_bson_object_id
      end

      it "returns the array as a string" do
        expect(converted).to eq(array.pack("C*"))
      end
    end

    context "when the array does not have 12 elements" do

      it "raises an exception" do
        expect {
          [ 1 ].to_bson_object_id
        }.to raise_error(BSON::ObjectId::Invalid)
      end
    end
  end
end
