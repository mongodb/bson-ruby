require 'spec_helper'

describe BSON::ByteBuffer do

  describe '#allocate' do

    let(:buffer) do
      described_class.allocate
    end

    it 'allocates a buffer' do
      expect(buffer).to be_a(BSON::ByteBuffer)
    end
  end

  describe '#length' do

    context 'when the byte buffer is initialized with no bytes' do

      let(:buffer) do
        described_class.new
      end

      before do
        buffer.put_int32(5)
      end

      it 'returns the length of the buffer' do
        expect(buffer.length).to eq(4)
      end
    end

    context 'when the byte buffer is initialized with some bytes' do

      let(:buffer) do
        described_class.new("#{BSON::Int32::BSON_TYPE}#{BSON::Int32::BSON_TYPE}")
      end

      it 'returns the length' do
        expect(buffer.length).to eq(2)
      end
    end
  end
end
