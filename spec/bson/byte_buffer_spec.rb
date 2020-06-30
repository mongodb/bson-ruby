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
    context 'empty buffer' do

      let(:buffer) do
        described_class.new
      end

      it 'is zero' do
        expect(buffer.length).to eq(0)
      end
    end

    context 'when the byte buffer is initialized with no bytes' do

      let(:buffer) do
        described_class.new
      end
      
      context '#put_int32' do 
        before do
          buffer.put_int32(5)
        end

        it 'returns the length of the buffer' do
          expect(buffer.length).to eq(4)
        end
      end

      context '#put_uint32' do 
        context 'when number is in range' do 
          before do
            buffer.put_uint32(5)
          end

          it 'returns the length of the buffer' do
            expect(buffer.length).to eq(4)
          end
        end

        context 'when number doesn\'t fit in signed int32' do 
          let(:modified) do
            buffer.put_uint32(4294967295)
          end

          let(:expected) do
            [ 4294967295 ].pack(BSON::Int32::PACK)
          end

          it 'appends the int32 to the byte buffer' do
            expect(modified.to_s).to eq(expected)
          end

          it 'get returns correct number' do
            expect(modified.get_uint32).to eq(4294967295)
          end

          it 'returns the length of the buffer' do
            expect(modified.length).to eq(4)
          end
        end

        context 'when number is not in range' do 
          it 'raises error on out of top range' do
            expect{ buffer.put_uint32(4294967296) }.to raise_error(RangeError)
          end

          it 'raises error on out of bottom range' do
            expect{ buffer.put_uint32(-1) }.to raise_error(RangeError)
          end
        end
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

    it 'does not change write position' do
      buffer = described_class.new
      buffer.put_byte(BSON::Int32::BSON_TYPE)
      expect(buffer.write_position).to eq(1)
      buffer.rewind!
      expect(buffer.write_position).to eq(1)
    end
  end
end
