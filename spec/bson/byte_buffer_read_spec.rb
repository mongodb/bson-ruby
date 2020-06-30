require 'spec_helper'

describe BSON::ByteBuffer do

  describe '#get_byte' do

    let(:buffer) do
      described_class.new(BSON::Int32::BSON_TYPE)
    end

    let!(:byte) do
      buffer.get_byte
    end

    it 'gets the byte from the buffer' do
      expect(byte).to eq(BSON::Int32::BSON_TYPE)
    end

    it 'increments the read position by 1' do
      expect(buffer.read_position).to eq(1)
    end
  end

  describe '#get_bytes' do

    let(:string) do
      "#{BSON::Int32::BSON_TYPE}#{BSON::Int32::BSON_TYPE}"
    end

    let(:buffer) do
      described_class.new(string)
    end

    let!(:bytes) do
      buffer.get_bytes(2)
    end

    it 'gets the bytes from the buffer' do
      expect(bytes).to eq(string)
    end

    it 'increments the position by the length' do
      expect(buffer.read_position).to eq(string.bytesize)
    end
  end

  describe '#get_cstring' do

    let(:buffer) do
      described_class.new("testing#{BSON::NULL_BYTE}")
    end

    let!(:string) do
      buffer.get_cstring
    end

    it 'gets the cstring from the buffer' do
      expect(string).to eq("testing")
    end

    it 'increments the position by string length + 1' do
      expect(buffer.read_position).to eq(8)
    end
  end

  describe '#get_double' do

    let(:buffer) do
      described_class.new(12.5.to_bson.to_s)
    end

    let!(:double) do
      buffer.get_double
    end

    it 'gets the double from the buffer' do
      expect(double).to eq(12.5)
    end

    it 'increments the read position by 8' do
      expect(buffer.read_position).to eq(8)
    end
  end

  describe '#get_int32' do

    let(:buffer) do
      described_class.new(12.to_bson.to_s)
    end

    let!(:int32) do
      buffer.get_int32
    end

    it 'gets the int32 from the buffer' do
      expect(int32).to eq(12)
    end

    it 'increments the position by 4' do
      expect(buffer.read_position).to eq(4)
    end
  end

  describe '#get_uint32' do
    context 'when using 2^32-1' do
      let(:buffer) do
        described_class.new(4294967295.to_bson.to_s)
      end

      let!(:int32) do
        buffer.get_uint32
      end

      it 'gets the uint32 from the buffer' do
        expect(int32).to eq(4294967295)
      end

      it 'increments the position by 4' do
        expect(buffer.read_position).to eq(4)
      end
    end
    
    context 'when using 2^32-2' do
      let(:buffer) do
        described_class.new(4294967294.to_bson.to_s)
      end

      let!(:int32) do
        buffer.get_uint32
      end

      it 'gets the uint32 from the buffer' do
        expect(int32).to eq(4294967294)
      end

      it 'increments the position by 4' do
        expect(buffer.read_position).to eq(4)
      end
    end

    context 'when using 0' do
      let(:buffer) do
        described_class.new(0.to_bson.to_s)
      end

      let!(:int32) do
        buffer.get_uint32
      end

      it 'gets the uint32 from the buffer' do
        expect(int32).to eq(0)
      end

      it 'increments the position by 4' do
        expect(buffer.read_position).to eq(4)
      end
    end
  end

  describe '#get_int64' do

    let(:buffer) do
      described_class.new((Integer::MAX_64BIT - 1).to_bson.to_s)
    end

    let!(:int64) do
      buffer.get_int64
    end

    it 'gets the int64 from the buffer' do
      expect(int64).to eq(Integer::MAX_64BIT - 1)
    end

    it 'increments the position by 8' do
      expect(buffer.read_position).to eq(8)
    end
  end

  describe '#get_string' do

    let(:buffer) do
      described_class.new("#{8.to_bson.to_s}testing#{BSON::NULL_BYTE}")
    end

    let!(:string) do
      buffer.get_string
    end

    it 'gets the string from the buffer' do
      expect(string).to eq("testing")
    end

    it 'increments the position by string length + 5' do
      expect(buffer.read_position).to eq(12)
    end
  end
end
