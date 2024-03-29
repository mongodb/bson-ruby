# frozen_string_literal: true
# rubocop:todo all

require 'spec_helper'
require 'json'

# These tests are copied from driver when the driver implemented Mongo:DBRef
# class, and are intended to verify that the current DBRef implementation is
# compatible with the legacy driver DBRef interface.

# For testing a class that emits warnings, without spamming the terminal
# with them.
def silenced_version_of(klass)
  Class.new(klass) do
    class <<self
      def name
        "#{superclass.name} (silenced)"
      end

      alias to_s name
    end

    def warn(*_args)
    end
  end
end

describe silenced_version_of BSON::DBRef do

  let(:object_id) do
    BSON::ObjectId.new
  end

  describe '#as_json' do

    context 'when the database is not provided' do

      let(:dbref) do
        described_class.new('users', object_id)
      end

      it 'returns the json document without database' do
        expect(dbref.as_json).to eq({ '$ref' => 'users', '$id' => object_id })
      end
    end

    context 'when the database is provided' do

      let(:dbref) do
        described_class.new('users', object_id, 'database')
      end

      it 'returns the json document with database' do
        expect(dbref.as_json).to eq({
          '$ref' => 'users',
          '$id' => object_id,
          '$db' => 'database'
        })
      end
    end
  end

  describe '#initialize' do

    let(:dbref) do
      described_class.new('users', object_id)
    end

    it 'sets the collection' do
      expect(dbref.collection).to eq('users')
    end

    it 'sets the id' do
      expect(dbref.id).to eq(object_id)
    end

    context 'when a database is provided' do

      let(:dbref) do
        described_class.new('users', object_id, 'db')
      end

      it 'sets the database' do
        expect(dbref.database).to eq('db')
      end

      context 'when id is not provided' do

        let(:dbref) do
          described_class.new('users', nil, 'db')
        end

        it 'raises ArgumentError' do
          lambda do
            dbref
          end.should raise_error(BSON::Error::InvalidDBRefArgument)
        end
      end
    end
  end

  describe '#to_bson' do

    let(:dbref) do
      described_class.new('users', object_id, 'database')
    end

    it 'converts the underlying document to bson' do
      expect(dbref.to_bson.to_s).to eq(dbref.as_json.to_bson.to_s)
    end
  end

  describe '#to_json' do

    context 'when the database is not provided' do

      let(:dbref) do
        described_class.new('users', object_id)
      end

      it 'returns the json document without database' do
        expect(dbref.to_json).to eq("{\"$ref\":\"users\",\"$id\":#{object_id.to_json}}")
      end
    end

    context 'when the database is provided' do

      let(:dbref) do
        described_class.new('users', object_id, 'database')
      end

      it 'returns the json document with database' do
        expect(dbref.to_json).to eq("{\"$ref\":\"users\",\"$id\":#{object_id.to_json},\"$db\":\"database\"}")
      end
    end
  end

  describe '#from_bson' do

    let(:buffer) do
      dbref.to_bson
    end

    let(:decoded) do
      BSON::Document.from_bson(BSON::ByteBuffer.new(buffer.to_s))
    end

    context 'when a database exists' do

      let(:dbref) do
        described_class.new('users', object_id, 'database')
      end

      it 'decodes the ref' do
        expect(decoded.collection).to eq('users')
      end

      it 'decodes the id' do
        expect(decoded.id).to eq(object_id)
      end

      it 'decodes the database' do
        expect(decoded.database).to eq('database')
      end
    end

    context 'when no database exists' do

      let(:dbref) do
        described_class.new('users', object_id)
      end

      it 'decodes the ref' do
        expect(decoded.collection).to eq('users')
      end

      it 'decodes the id' do
        expect(decoded.id).to eq(object_id)
      end

      it 'sets the database to nil' do
        expect(decoded.database).to be_nil
      end
    end
  end
end
