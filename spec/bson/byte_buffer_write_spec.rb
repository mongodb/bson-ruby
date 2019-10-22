require 'spec_helper'

describe BSON::ByteBuffer do

  let(:buffer) do
    described_class.new
  end

  shared_examples_for 'does not write' do
    it 'raises ArgumentError' do
      expect do
        modified
      end.to raise_error(ArgumentError)
    end

    it 'does not change write position' do
      expect do
        modified
      end.to raise_error(ArgumentError)

      expect(buffer.write_position).to eq(0)
    end
  end

  describe '#put_byte' do

    let(:modified) do
      buffer.put_byte(BSON::Int32::BSON_TYPE)
    end

    it 'appends the byte to the byte buffer' do
      expect(modified.to_s).to eq(BSON::Int32::BSON_TYPE.chr)
    end

    it 'increments the write position by 1' do
      expect(modified.write_position).to eq(1)
    end

    context 'when it receives a numeric value' do
      it 'raises the ArgumentError exception' do
        expect{buffer.put_byte(1)}.to raise_error(ArgumentError)
      end
    end

    context 'when it receives a nil value' do
      it 'raises the ArgumentError exception' do
        expect{buffer.put_byte(nil)}.to raise_error(ArgumentError)
      end
    end

    context 'when given a string of length > 1' do

      let(:modified) do
        buffer.put_byte('xx')
      end

      it_behaves_like 'does not write'
    end

    context 'when given a string of length 0' do

      let(:modified) do
        buffer.put_byte('')
      end

      it_behaves_like 'does not write'
    end
  end

  describe '#put_bytes' do

    let(:modified) do
      buffer.put_bytes(BSON::Int32::BSON_TYPE)
      buffer
    end

    it 'increments the write position by 1' do
      expect(modified.write_position).to eq(1)
    end

    context 'when it receives a numeric value' do
      it 'raises the ArgumentError exception' do
        expect{buffer.put_bytes(1)}.to raise_error(ArgumentError)
      end
    end

    context 'when it receives a nil value' do
      it 'raises the ArgumentError exception' do
        expect{buffer.put_bytes(nil)}.to raise_error(ArgumentError)
      end
    end

    context 'when given a string with null bytes' do
      let(:byte_str) { "\x00\xef\xfe\x00" }

      let(:modified) do
        buffer.put_bytes(byte_str)
      end

      before do
        expect(buffer.write_position).to eq(0)
        expect(byte_str.length).to eq(4)
      end

      it 'writes the string' do
        expect(modified.write_position).to eq(4)
      end
    end
  end

  describe '#put_string' do

    context 'when the buffer does not need to be expanded' do

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

    context 'given empty string' do
      let(:modified) do
        buffer.put_string('')
      end

      it 'writes length and null terminator' do
        expect(modified.write_position).to eq(5)
      end
    end
  end

  describe '#put_cstring' do

    context 'when argument is a string' do
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

        it 'mutates receiver' do
          modified
          expect(buffer.write_position).to eq(8)
        end
      end

      context "when the string contains a null byte" do

        let(:string) do
          "test#{BSON::NULL_BYTE}ing"
        end

        it 'raises ArgumentError' do
          expect {
            buffer.put_cstring(string)
          }.to raise_error(ArgumentError, /String .* contains null bytes/)
        end
      end
    end

    context 'when argument is a symbol' do
      let(:modified) do
        buffer.put_cstring(:testing)
      end

      it 'writes' do
        expect(modified.to_s).to eq("testing#{BSON::NULL_BYTE}")
      end

      it 'increments the write position by the length + 1' do
        expect(modified.write_position).to eq(8)
      end

      it 'mutates receiver' do
        modified
        expect(buffer.write_position).to eq(8)
      end

      context 'when symbol includes a null byte' do
        let(:modified) do
          buffer.put_cstring(:"tes\x00ing")
        end

        it 'raises ArgumentError' do
          expect {
            modified
          }.to raise_error(ArgumentError, /String .* contains null bytes/)
        end

        it 'does not change write position' do
          begin
            buffer.put_cstring(:"tes\x00ing")
          rescue ArgumentError
          end

          expect(buffer.write_position).to eq(0)
        end
      end
    end

    context 'when argument is a Fixnum' do
      let(:modified) do
        buffer.put_cstring(1234)
      end

      it 'writes' do
        expect(modified.to_s).to eq("1234#{BSON::NULL_BYTE}")
      end

      it 'increments the write position by the length + 1' do
        expect(modified.write_position).to eq(5)
      end
    end

    context 'when argument is of an unsupported type' do
      let(:modified) do
        buffer.put_cstring(1234.0)
      end

      it 'raises TypeError' do
        expect do
          modified
        end.to raise_error(TypeError, /Invalid type for put_cstring/)
      end

      it 'does not change write position' do
        begin
          buffer.put_cstring(1234.0)
        rescue TypeError
        end

        expect(buffer.write_position).to eq(0)
      end
    end
  end

  describe '#put_symbol' do
    context 'normal symbol' do
      let(:modified) do
        buffer.put_symbol(:hello)
      end

      it 'writes the symbol as string' do
        expect(modified.to_s).to eq("\x06\x00\x00\x00hello\x00")
      end

      it 'advances write position' do
        # 4 byte length + 5 byte string + null byte
        expect(modified.write_position).to eq(10)
      end
    end

    context 'symbol with null byte' do
      let(:modified) do
        buffer.put_symbol(:"he\x00lo")
      end

      it 'writes the symbol as string' do
        expect(modified.to_s).to eq("\x06\x00\x00\x00he\x00lo\x00")
      end

      it 'advances write position' do
        # 4 byte length + 5 byte string + null byte
        expect(modified.write_position).to eq(10)
      end
    end
  end

  describe '#put_double' do

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

    context 'when integer fits in 32 bits' do
      let(:modified) do
        buffer.put_int64(1)
      end

      it 'increments the write position by 8' do
        expect(modified.write_position).to eq(8)
      end
    end
  end

  describe '#replace_int32' do

    let(:exp_0) do
      [ 0 ].pack(BSON::Int32::PACK)
    end

    let(:exp_first) do
      [ 5 ].pack(BSON::Int32::PACK)
    end

    let(:exp_second) do
      [ 4 ].pack(BSON::Int32::PACK)
    end

    let(:exp_42) do
      [ 42 ].pack(BSON::Int32::PACK)
    end

    before do
      buffer.put_int32(0).put_int32(4)
    end

    let(:modified) do
      buffer.replace_int32(0, 5)
    end

    it 'replaces the int32 at the location' do
      expect(modified.to_s).to eq("#{exp_first}#{exp_second}")
    end

    context 'when the position is negative' do

      let(:modified) do
        buffer.replace_int32(-1, 5)
      end

      it 'raises ArgumentError' do
        expect do
          modified
        end.to raise_error(ArgumentError, /Position.*cannot be negative/)
      end
    end

    context 'when the position is 4 bytes prior to write position' do

      let(:modified) do
        buffer.replace_int32(4, 42)
      end

      it 'replaces the int32 at the location' do
        expect(modified.to_s).to eq("#{exp_0}#{exp_42}")
      end
    end

    context 'when the position exceeds allowed range' do

      let(:modified) do
        # Buffer has 8 bytes but we can only write up to position 4
        buffer.replace_int32(5, 42)
      end

      it 'raises ArgumentError' do
        expect do
          modified
        end.to raise_error(ArgumentError, /Position.*is out of bounds/)
      end
    end
  end
end
