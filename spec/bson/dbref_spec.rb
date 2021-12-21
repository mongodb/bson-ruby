# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'
require 'json'

describe BSON::DBRef do

  let(:object_id) do
    BSON::ObjectId.new
  end

  describe '#as_json' do

    context 'when the database is not provided' do

      let(:dbref) do
        described_class.new({ '$ref' => 'users', '$id' => object_id })
      end

      it 'returns the json document without database' do
        expect(dbref.as_json).to eq({ '$ref' => 'users', '$id' => object_id })
      end
    end

    context 'when the database is provided' do

      let(:dbref) do
        described_class.new({ '$ref' => 'users', '$id' => object_id, '$db' => 'database' })
      end

      it 'returns the json document with database' do
        expect(dbref.as_json).to eq({
          '$ref' => 'users',
          '$id' => object_id,
          '$db' => 'database'
        })
      end
    end

    context 'when other keys are provided' do

      let(:dbref) do
        described_class.new({ '$ref' => 'users', '$id' => object_id, '$db' => 'database', 'x' => 'y' })
      end

      it 'returns the json document with the other keys' do
        expect(dbref.as_json).to eq({
          '$ref' => 'users',
          '$id' => object_id,
          '$db' => 'database',
          'x' => 'y'
        })
      end
    end
  end

  describe '#initialize' do

    let(:dbref) do
      described_class.new(hash)
    end

    let(:hash) do
      { '$ref' => 'users', '$id' => object_id }
    end

    it 'sets the collection' do
      expect(dbref.collection).to eq('users')
    end

    it 'sets the id' do
      expect(dbref.id).to eq(object_id)
    end

    context 'when a database is provided' do

      let(:hash) do
        { '$ref' => 'users', '$id' => object_id, '$db' => 'db' }
      end

      it 'sets the database' do
        expect(dbref.database).to eq('db')
      end
    end

    context 'when not providing a collection' do
      let(:hash) do
        { '$id' => object_id, '$db' => 'db' }
      end

      it 'raises an error' do
        expect do
          dbref
        end.to raise_error(ArgumentError, /DBRefs must have a \$ref/)
      end
    end

    context 'when not providing an id' do
      let(:hash) do
        { '$ref' => 'users', '$db' => 'db' }
      end

      it 'raises an error' do
        expect do
          dbref
        end.to raise_error(ArgumentError, /DBRefs must have a \$id/)
      end
    end

    context 'when providing an invalid type for ref' do
      let(:hash) do
        { '$ref' => 1, '$id' => object_id }
      end

      it 'raises an error' do
        expect do
          dbref
        end.to raise_error(ArgumentError, /The value for key \$ref must be a string/)
      end
    end

    context 'when providing an invalid type for database' do
      let(:hash) do
        { '$ref' => 'users', '$id' => object_id, '$db' => 1 }
      end

      it 'raises an error' do
        expect do
          dbref
        end.to raise_error(ArgumentError, /The value for key \$db must be a string/)
      end
    end
  end

  describe '#to_bson' do

    let(:dbref) do
      described_class.new({ '$ref' => 'users', '$id' => object_id, '$db' => 'database' })
    end

    it 'converts the underlying document to bson' do
      expect(dbref.to_bson.to_s).to eq(dbref.as_json.to_bson.to_s)
    end
  end

  describe '#to_json' do

    context 'when the database is not provided' do

      let(:dbref) do
        described_class.new({ '$ref' => 'users', '$id' => object_id })
      end

      it 'returns the json document without database' do
        expect(dbref.to_json).to eq("{\"$ref\":\"users\",\"$id\":#{object_id.to_json}}")
      end
    end

    context 'when the database is provided' do

      let(:dbref) do
        described_class.new({ '$ref' => 'users', '$id' => object_id, '$db' => 'database' })
      end

      it 'returns the json document with database' do
        expect(dbref.to_json).to eq("{\"$ref\":\"users\",\"$id\":#{object_id.to_json},\"$db\":\"database\"}")
      end
    end

    context 'when other keys are provided' do

      let(:dbref) do
        described_class.new({ '$ref' => 'users', '$id' => object_id, '$db' => 'database', 'x' => 'y' })
      end

      it 'returns the json document with the other keys' do
        expect(dbref.to_json).to eq("{\"$ref\":\"users\",\"$id\":#{object_id.to_json},\"$db\":\"database\",\"x\":\"y\"}")
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
        described_class.new({ '$ref' => 'users', '$id' => object_id, '$db' => 'database' })
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
        described_class.new({ '$ref' => 'users', '$id' => object_id })
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

    context 'when other keys exist' do

      let(:dbref) do
        described_class.new({ '$ref' => 'users', '$id' => object_id, 'x' => 'y' })
      end

      it 'decodes the key' do
        expect(decoded['x']).to eq('y')
      end
    end
  end
end
