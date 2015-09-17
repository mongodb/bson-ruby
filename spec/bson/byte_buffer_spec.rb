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

  describe '#put_byte' do

    let(:buffer) do
      described_class.new
    end

    let(:modified) do
      buffer.put_byte(BSON::Integer::INT32_TYPE)
    end

    it 'appends the int32 to the byte buffer' do
      expect(modified.to_s).to eq(BSON::Integer::INT32_TYPE.chr)
    end
  end

  describe '#put_cstring' do

    let(:buffer) do
      described_class.new
    end

    let(:modified) do
      buffer.put_cstring('testing')
    end

    it 'appends the string plus null byte to the byte buffer' do
      expect(modified.to_s).to eq("testing#{BSON::NULL_BYTE}")
    end
  end

  describe '#put_double' do

    let(:buffer) do
      described_class.new
    end

    let(:modified) do
      buffer.put_double(1.2332)
    end

    it 'appends the double to the buffer' do
      expect(modified.to_s).to eq([ 1.2332 ].pack(Float::PACK))
    end
  end

  describe '#put_int32' do

    let(:buffer) do
      described_class.new
    end

    context 'when the integer is 32 bit' do

      let(:modified) do
        buffer.put_int32(Integer::MAX_32BIT - 1)
      end

      let(:expected) do
        [ Integer::MAX_32BIT - 1 ].pack(BSON::Int32::PACK)
      end

      it 'appends the int32 to the byte buffer' do
        expect(modified.to_s).to eq(expected)
      end
    end
  end

  describe '#put_int64' do

    let(:buffer) do
      described_class.new
    end

    context 'when the integer is 64 bit' do

      let(:modified) do
        buffer.put_int64(Integer::MAX_64BIT - 1)
      end

      let(:expected) do
        [ Integer::MAX_64BIT - 1 ].pack(BSON::Int64::PACK)
      end

      it 'appends the int64 to the byte buffer' do
        expect(modified.to_s).to eq(expected)
      end
    end
  end

  describe '#put_string' do

    let(:buffer) do
      described_class.new
    end

    let(:modified) do
      buffer.put_string('testing')
    end

    it 'appends the string to the byte buffer' do
      expect(modified.to_s).to eq("#{8.to_bson.to_s}testing#{BSON::NULL_BYTE}")
    end
  end

  describe '#replace_int32' do

    let(:buffer) do
      described_class.new
    end

    let(:exp_first) do
      [ 5 ].pack(BSON::Int32::PACK)
    end

    let(:exp_second) do
      [ 4 ].pack(BSON::Int32::PACK)
    end

    let(:modified) do
      buffer.put_int32(0).put_int32(4).replace_int32(0, 5)
    end

    it 'replaces the int32 at the location' do
      expect(modified.to_s).to eq("#{exp_first}#{exp_second}")
    end
  end
end
