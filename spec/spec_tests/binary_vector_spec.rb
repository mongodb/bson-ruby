# rubocop:todo all
require 'spec_helper'
require 'runners/binary_vector'

describe 'Binary vector tests' do
  specs = BINARY_VECTOR_TESTS.map { |file| BSON::BinaryVector::Spec.new(file) }
  skipped_tests = [
    'Overflow Vector INT8',
    'Underflow Vector INT8',
    'INT8 with float inputs',
    'Overflow Vector PACKED_BIT',
    'Underflow Vector PACKED_BIT',
    'Vector with float values PACKED_BIT'
  ]
  [true, false].each do |use_vector_type|
    context "use vector type: #{use_vector_type}" do
      specs.each do |spec|
        context(spec.description) do
          spec.valid_tests.each do |test|
            context(test.description) do
              it 'encodes a document' do
                expect(test.canonical_bson_from_document(use_vector_type: use_vector_type)).to eq(test.bson)
              end

              it 'decodes BSON' do
                binary = test.document_from_canonical_bson[spec.test_key]
                expect(binary.type).to eq(:vector)
                vector = binary.as_vector
                expect(vector.dtype).to eq(test.dtype)
                expect(vector.padding).to eq(test.padding)
                if vector.dtype == :float32
                  vector.each_with_index do |v, i|
                    if v == Float::INFINITY || v == -Float::INFINITY
                      expect(v).to eq(test.vector[i])
                    else
                      expect(v).to be_within(0.00001).of(test.vector[i])
                    end
                  end
                else
                  expect(vector).to eq(test.vector)
                end
              end
            end
          end

          spec.invalid_tests.each do |test|
            context(test.description) do
              let(:subject) do
                if test.vector
                  ->(vvd) { test.canonical_bson_from_document(use_vector_type: use_vector_type, validate_vector_data: vvd) }
                else
                  ->() { test.document_from_canonical_bson }
                end
              end
              context 'with data validation' do
                it 'raises' do
                  expect {
                    subject.call(true)
                  }.to raise_error do |err|
                    expect([ArgumentError, BSON::Error]).to include(err.class)
                  end
                end
              end

              context 'without data validation' do
                it 'raises' do
                  skip 'Ruby Array.pack does not validate input' if skipped_tests.include?(test.description)

                  expect {
                    subject.call(false)
                  }.to raise_error do |err|
                    expect([ArgumentError, BSON::Error]).to include(err.class)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
