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
      described_class.new("#{12.5.to_bson.to_s}")
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
      described_class.new("#{12.to_bson.to_s}")
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

  describe '#get_int64' do

    let(:buffer) do
      described_class.new("#{(Integer::MAX_64BIT - 1).to_bson.to_s}")
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

    let!(:modified) do
      buffer.put_byte(BSON::Int32::BSON_TYPE)
    end

    it 'appends the byte to the byte buffer' do
      expect(modified.to_s).to eq(BSON::Int32::BSON_TYPE.chr)
    end

    it 'increments the write position by 1' do
      expect(modified.write_position).to eq(1)
    end
  end

  describe '#put_cstring' do

    let(:buffer) do
      described_class.new
    end

    context 'when the string is valid' do

      let!(:modified) do
        buffer.put_cstring('testing')
      end

      it 'appends the string plus null byte to the byte buffer' do
        expect(modified.to_s).to eq("testing#{BSON::NULL_BYTE}")
      end

      it 'increments the write position by the length + 1' do
        expect(modified.write_position).to eq(8)
      end
    end

    context "when the string contains a null byte" do

      let(:string) do
        "test#{BSON::NULL_BYTE}ing"
      end

      it "raises an error" do
        expect {
          buffer.put_cstring(string)
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#put_double' do

    let(:buffer) do
      described_class.new
    end

    let!(:modified) do
      buffer.put_double(1.2332)
    end

    it 'appends the double to the buffer' do
      expect(modified.to_s).to eq([ 1.2332 ].pack(Float::PACK))
    end

    it 'increments the write position by 8' do
      expect(modified.write_position).to eq(8)
    end
  end

  describe '#put_int32' do

    let(:buffer) do
      described_class.new
    end

    context 'when the integer is 32 bit' do

      context 'when the integer is positive' do

        let!(:modified) do
          buffer.put_int32(Integer::MAX_32BIT - 1)
        end

        let(:expected) do
          [ Integer::MAX_32BIT - 1 ].pack(BSON::Int32::PACK)
        end

        it 'appends the int32 to the byte buffer' do
          expect(modified.to_s).to eq(expected)
        end

        it 'increments the write position by 4' do
          expect(modified.write_position).to eq(4)
        end
      end

      context 'when the integer is negative' do

        let!(:modified) do
          buffer.put_int32(Integer::MIN_32BIT + 1)
        end

        let(:expected) do
          [ Integer::MIN_32BIT + 1 ].pack(BSON::Int32::PACK)
        end

        it 'appends the int32 to the byte buffer' do
          expect(modified.to_s).to eq(expected)
        end

        it 'increments the write position by 4' do
          expect(modified.write_position).to eq(4)
        end
      end

      context 'when the integer is not 32 bit' do

        it 'raises an exception' do
          expect {
            buffer.put_int32(Integer::MAX_64BIT - 1)
          }.to raise_error(RangeError)
        end
      end
    end
  end

  describe '#put_int64' do

    let(:buffer) do
      described_class.new
    end

    context 'when the integer is 64 bit' do

      context 'when the integer is positive' do

        let!(:modified) do
          buffer.put_int64(Integer::MAX_64BIT - 1)
        end

        let(:expected) do
          [ Integer::MAX_64BIT - 1 ].pack(BSON::Int64::PACK)
        end

        it 'appends the int64 to the byte buffer' do
          expect(modified.to_s).to eq(expected)
        end

        it 'increments the write position by 8' do
          expect(modified.write_position).to eq(8)
        end
      end

      context 'when the integer is negative' do

        let!(:modified) do
          buffer.put_int64(Integer::MIN_64BIT + 1)
        end

        let(:expected) do
          [ Integer::MIN_64BIT + 1 ].pack(BSON::Int64::PACK)
        end

        it 'appends the int64 to the byte buffer' do
          expect(modified.to_s).to eq(expected)
        end

        it 'increments the write position by 8' do
          expect(modified.write_position).to eq(8)
        end
      end

      context 'when the integer is larger than 64 bit' do

        it 'raises an exception' do
          expect {
            buffer.put_int64(Integer::MAX_64BIT + 1)
          }.to raise_error(RangeError)
        end
      end
    end
  end

  describe '#put_string' do

    context 'when the buffer does not need to be expanded' do

      let(:buffer) do
        described_class.new
      end

      context 'when the string is UTF-8' do

        let!(:modified) do
          buffer.put_string('testing')
        end

        it 'appends the string to the byte buffer' do
          expect(modified.to_s).to eq("#{8.to_bson.to_s}testing#{BSON::NULL_BYTE}")
        end

        it 'increments the write position by length + 5' do
          expect(modified.write_position).to eq(12)
        end
      end
    end

    context 'when the buffer needs to be expanded' do

      let(:buffer) do
        described_class.new
      end

      let(:string) do
        300.times.inject(""){ |s, i| s << "#{i}" }
      end

      context 'when no bytes exist in the buffer' do

        let!(:modified) do
          buffer.put_string(string)
        end

        it 'appends the string to the byte buffer' do
          expect(modified.to_s).to eq("#{(string.bytesize + 1).to_bson.to_s}#{string}#{BSON::NULL_BYTE}")
        end

        it 'increments the write position by length + 5' do
          expect(modified.write_position).to eq(string.bytesize + 5)
        end
      end

      context 'when bytes exist in the buffer' do

        let!(:modified) do
          buffer.put_int32(4).put_string(string)
        end

        it 'appends the string to the byte buffer' do
          expect(modified.to_s).to eq(
            "#{[ 4 ].pack(BSON::Int32::PACK)}#{(string.bytesize + 1).to_bson.to_s}#{string}#{BSON::NULL_BYTE}"
          )
        end

        it 'increments the write position by length + 5' do
          expect(modified.write_position).to eq(string.bytesize + 9)
        end
      end
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

  describe '#rewind!' do

    shared_examples_for 'a rewindable buffer' do

      let(:string) do
        "#{BSON::Int32::BSON_TYPE}#{BSON::Int32::BSON_TYPE}"
      end

      before do
        buffer.get_bytes(1)
        buffer.rewind!
      end

      it 'resets the read position to 0' do
        expect(buffer.read_position).to eq(0)
      end

      it 'starts subsequent reads at position 0' do
        expect(buffer.get_bytes(2)).to eq(string)
      end
    end

    context 'when the buffer is instantiated with a string' do

      let(:buffer) do
        described_class.new(string)
      end

      it_behaves_like 'a rewindable buffer'
    end

    context 'when the buffer is instantiated with nothing' do

      let(:buffer) do
        described_class.new
      end

      before do
        buffer.put_byte(BSON::Int32::BSON_TYPE).put_byte(BSON::Int32::BSON_TYPE)
      end

      it_behaves_like 'a rewindable buffer'
    end
  end
end
