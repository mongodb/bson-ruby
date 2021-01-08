# Copyright (C) 2019-2020 MongoDB Inc.
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
require "base64"

describe "BSON::Binary - UUID spec tests" do
  def make_binary(uuid_hex_str, type)
    uuid_binary_str = uuid_hex_str.scan(/../).map(&:hex).map(&:chr).join
    BSON::Binary.new(uuid_binary_str, type)
  end

  describe 'explicit encoding' do
    let(:uuid_str) { '00112233-4455-6677-8899-aabbccddeeff' }

    shared_examples_for 'creates binary' do
      it 'creates subtype 4 binary' do
        expect(binary.type).to eq(expected_type)
      end

      it 'creates binary with correct value' do
        expect(binary.data).to eq(expected_hex_value.scan(/../).map(&:hex).map(&:chr).join)
      end
    end

    context 'no representation' do
      let(:binary) { BSON::Binary.from_uuid(uuid_str) }
      let(:expected_type) { :uuid }
      let(:expected_hex_value) { '00112233445566778899AABBCCDDEEFF' }

      it_behaves_like 'creates binary'
    end

    context 'standard representation' do
      let(:binary) { BSON::Binary.from_uuid(uuid_str, :standard) }
      let(:expected_type) { :uuid }
      let(:expected_hex_value) { '00112233445566778899AABBCCDDEEFF' }

      it_behaves_like 'creates binary'
    end

    context 'csharp legacy representation' do
      let(:binary) { BSON::Binary.from_uuid(uuid_str, :csharp_legacy) }
      let(:expected_type) { :uuid_old }
      let(:expected_hex_value) { '33221100554477668899AABBCCDDEEFF' }

      it_behaves_like 'creates binary'
    end

    context 'java legacy representation' do
      let(:binary) { BSON::Binary.from_uuid(uuid_str, :java_legacy) }
      let(:expected_type) { :uuid_old }
      let(:expected_hex_value) { '7766554433221100FFEEDDCCBBAA9988' }

      it_behaves_like 'creates binary'
    end

    context 'python legacy representation' do
      let(:binary) { BSON::Binary.from_uuid(uuid_str, :python_legacy) }
      let(:expected_type) { :uuid_old }
      let(:expected_hex_value) { '00112233445566778899AABBCCDDEEFF' }

      it_behaves_like 'creates binary'
    end
  end

  describe 'explicit decoding' do
    context ':uuid, standard encoded' do
      let(:binary) { make_binary("00112233445566778899AABBCCDDEEFF", :uuid) }

      it 'decodes without arguments' do
        expect(binary.to_uuid.gsub('-', '').upcase).to eq("00112233445566778899AABBCCDDEEFF")
      end

      it 'decodes as standard' do
        expect(binary.to_uuid(:standard).gsub('-', '').upcase).to eq("00112233445566778899AABBCCDDEEFF")
      end

      it 'does not decode as csharp legacy' do
        expect do
          binary.to_uuid(:csharp_legacy)
        end.to raise_error(ArgumentError, /Binary of type :uuid can only be stringified to :standard representation/)
      end

      it 'does not decode as java legacy' do
        expect do
          binary.to_uuid(:java_legacy)
        end.to raise_error(ArgumentError, /Binary of type :uuid can only be stringified to :standard representation/)
      end

      it 'does not decode as python legacy' do
        expect do
          binary.to_uuid(:python_legacy)
        end.to raise_error(ArgumentError, /Binary of type :uuid can only be stringified to :standard representation/)
      end
    end

    shared_examples_for 'a legacy uuid' do
      it 'does not decode without arguments' do
        expect do
          binary.to_uuid
        end.to raise_error(ArgumentError, /Representation must be specified for BSON::Binary objects of type :uuid_old/)
      end

      it 'does not decode as standard' do
        expect do
          binary.to_uuid(:standard)
        end.to raise_error(ArgumentError, /BSON::Binary objects of type :uuid_old cannot be stringified to :standard representation/)
      end
    end

    context ':uuid_old, csharp legacy encoded' do
      let(:binary) { make_binary("33221100554477668899AABBCCDDEEFF", :uuid_old) }

      it_behaves_like 'a legacy uuid'

      it 'decodes as csharp legacy' do
        expect(binary.to_uuid(:csharp_legacy).gsub('-', '').upcase).to eq("00112233445566778899AABBCCDDEEFF")
      end

      it 'decodes as java legacy' do
        expect(binary.to_uuid(:java_legacy).gsub('-', '').upcase).not_to eq("00112233445566778899AABBCCDDEEFF")
      end

      it 'decodes as python legacy' do
        expect(binary.to_uuid(:python_legacy).gsub('-', '').upcase).not_to eq("00112233445566778899AABBCCDDEEFF")
      end

      it 'expects four dashes when output as String' do
        expect(binary.to_uuid(:csharp_legacy)).to eq("00112233-4455-6677-8899-aabbccddeeff")
      end
    end

    context ':uuid_old, java legacy encoded' do
      let(:binary) { make_binary("7766554433221100FFEEDDCCBBAA9988", :uuid_old) }

      it_behaves_like 'a legacy uuid'

      it 'decodes as csharp legacy' do
        expect(binary.to_uuid(:csharp_legacy).gsub('-', '').upcase).not_to eq("00112233445566778899AABBCCDDEEFF")
      end

      it 'decodes as java legacy' do
        expect(binary.to_uuid(:java_legacy).gsub('-', '').upcase).to eq("00112233445566778899AABBCCDDEEFF")
      end

      it 'decodes as python legacy' do
        expect(binary.to_uuid(:python_legacy).gsub('-', '').upcase).not_to eq("00112233445566778899AABBCCDDEEFF")
      end

      it 'expects four dashes when output as String' do
        expect(binary.to_uuid(:java_legacy)).to eq("00112233-4455-6677-8899-aabbccddeeff")
      end
    end

    context ':uuid_old, python legacy encoded' do
      let(:binary) { make_binary("00112233445566778899AABBCCDDEEFF", :uuid_old) }

      it_behaves_like 'a legacy uuid'

      it 'decodes as csharp legacy' do
        expect(binary.to_uuid(:csharp_legacy).gsub('-', '').upcase).not_to eq("00112233445566778899AABBCCDDEEFF")
      end

      it 'decodes as java legacy' do
        expect(binary.to_uuid(:java_legacy).gsub('-', '').upcase).not_to eq("00112233445566778899AABBCCDDEEFF")
      end

      it 'decodes as python legacy' do
        expect(binary.to_uuid(:python_legacy).gsub('-', '').upcase).to eq("00112233445566778899AABBCCDDEEFF")
      end

      it 'expects four dashes when output as String' do
        expect(binary.to_uuid(:python_legacy)).to eq("00112233-4455-6677-8899-aabbccddeeff")
      end
    end
  end
end
