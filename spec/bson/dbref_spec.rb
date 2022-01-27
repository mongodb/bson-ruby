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

    context 'when first argument is a hash and two arguments are provided' do

      let(:dbref) do
        described_class.new({:$ref => 'users', :$id => object_id}, object_id)
      end

      it 'raises ArgumentError' do
        lambda do
          dbref
        end.should raise_error(ArgumentError)
      end
    end

    context 'when first argument is a hash and three arguments are provided' do

      let(:dbref) do
        described_class.new({:$ref => 'users', :$id => object_id}, object_id, 'db')
      end

      it 'raises ArgumentError' do
        lambda do
          dbref
        end.should raise_error(ArgumentError)
      end
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
        end.to raise_error(ArgumentError, /DBRef must have \$ref/)
      end
    end

    context 'when not providing an id' do
      let(:hash) do
        { '$ref' => 'users', '$db' => 'db' }
      end

      it 'raises an error' do
        expect do
          dbref
        end.to raise_error(ArgumentError, /DBRef must have \$id/)
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

    context 'when providing the fieds as symbols' do
      let(:hash) do
        { :$ref => 'users', :$id => object_id, :$db => 'db' }
      end

      it 'does not raise an error' do
        expect do
          dbref
        end.to_not raise_error
      end
    end

    context 'when testing the ordering of the fields' do
      context 'when the fields are in order' do
        let(:hash) do
          { '$ref' => 'users', '$id' => object_id, '$db' => 'db' }
        end

        it 'has the correct order' do
          expect(dbref.keys).to eq(['$ref', '$id', '$db'])
        end
      end

      context 'when the fields are out of order' do
        let(:hash) do
          { '$db' => 'db', '$id' => object_id, '$ref' => 'users' }
        end

        it 'has the correct order' do
          expect(dbref.keys).to eq(['$ref', '$id', '$db'])
        end
      end

      context 'when there is no db' do
        let(:hash) do
          { '$id' => object_id, '$ref' => 'users' }
        end

        it 'has the correct order' do
          expect(dbref.keys).to eq(['$ref', '$id'])
        end
      end

      context 'when the there are other fields in order' do
        let(:hash) do
          { '$ref' => 'users', '$id' => object_id, '$db' => 'db', 'x' => 'y', 'y' => 'z' }
        end

        it 'has the correct order' do
          expect(dbref.keys).to eq(['$ref', '$id', '$db', 'x', 'y'])
        end
      end

      context 'when the there are other fields out of order' do
        let(:hash) do
          { 'y' => 'z', '$db' => 'db', '$id' => object_id, 'x' => 'y', '$ref' => 'users' }
        end

        it 'has the correct order' do
          expect(dbref.keys).to eq(['$ref', '$id', '$db', 'y', 'x'])
        end
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
      hash.to_bson
    end

    let(:decoded) do
      BSON::Document.from_bson(BSON::ByteBuffer.new(buffer.to_s))
    end

    context 'when a database exists' do

      let(:hash) do
        { '$ref' => 'users', '$id' => object_id, '$db' => 'database' }
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

      it 'is of class DBRef' do
        expect(decoded).to be_a described_class
      end
    end

    context 'when no database exists' do

      let(:hash) do
        { '$ref' => 'users', '$id' => object_id }
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

      it 'is of class DBRef' do
        expect(decoded).to be_a described_class
      end
    end

    context 'when other keys exist' do

      let(:hash) do
        { '$ref' => 'users', '$id' => object_id, 'x' => 'y' }
      end

      it 'decodes the key' do
        expect(decoded['x']).to eq('y')
      end

      it 'is of class DBRef' do
        expect(decoded).to be_a described_class
      end
    end

    context 'when it is an invalid dbref' do

      shared_examples 'bson document' do
        it 'should not raise' do
          expect do
            decoded
          end.to_not raise_error
        end

        it 'has the correct class' do
          expect(decoded).to be_a BSON::Document
          expect(decoded).to_not be_a described_class
        end
      end

      context 'when the hash has invalid collection type' do
        let(:hash) do
          { '$ref' => 1, '$id' => object_id }
        end
        include_examples 'bson document'
      end

      context 'when the hash has an invalid database type' do
        let(:hash) do
          { '$ref' => 'users', '$id' => object_id, '$db' => 1 }
        end
        include_examples 'bson document'
      end

      context 'when the hash is missing a collection' do
        let(:hash) do
          { '$id' => object_id }
        end
        include_examples 'bson document'
      end

      context 'when the hash is missing an id' do
        let(:hash) do
          { '$ref' => 'users' }
        end
        include_examples 'bson document'
      end
    end

    context 'when nesting the dbref' do

      context 'when it is a valid dbref' do
        let(:hash) do
          { 'dbref' => { '$ref' => 'users', '$id' => object_id } }
        end

        it 'should not raise' do
          expect do
            buffer
          end.to_not raise_error
        end

        it 'has the correct class' do
          expect(decoded['dbref']).to be_a described_class
        end
      end

      context 'when it is an invalid dbref' do

        shared_examples 'nested bson document' do
          it 'should not raise' do
            expect do
              decoded
            end.to_not raise_error
          end

          it 'has the correct class' do
            expect(decoded['dbref']).to be_a BSON::Document
            expect(decoded['dbref']).to_not be_a described_class
          end
        end

        context 'when the hash has invalid collection type' do
          let(:hash) do
            { 'dbref' => { '$ref' => 1, '$id' => object_id } }
          end
          include_examples 'nested bson document'
        end

        context 'when the hash has an invalid database type' do
          let(:hash) do
            { 'dbref' => { '$ref' => 'users', '$id' => object_id, '$db' => 1 } }
          end
          include_examples 'nested bson document'
        end

        context 'when the hash is missing a collection' do
          let(:hash) do
            { 'dbref' => { '$id' => object_id } }
          end
          include_examples 'nested bson document'
        end

        context 'when the hash is missing an id' do
          let(:hash) do
            { 'dbref' => { '$ref' => 'users' } }
          end
          include_examples 'nested bson document'
        end
      end
    end

    context 'when nesting a dbref inside a dbref' do
      context 'when it is a valid dbref' do
        let(:hash) do
          { 'dbref1' => { '$ref' => 'users', '$id' => object_id, 'dbref2' => { '$ref' => 'users', '$id' => object_id } } }
        end

        it 'should not raise' do
          expect do
            buffer
          end.to_not raise_error
        end

        it 'has the correct class' do
          expect(decoded['dbref1']).to be_a described_class
          expect(decoded['dbref1']['dbref2']).to be_a described_class
        end
      end

      context 'when it is an invalid dbref' do
        let(:hash) do
          { 'dbref' => { '$ref' => 'users', '$id' => object_id, 'dbref' => { '$ref' => 1, '$id' => object_id } } }
        end

        it 'should not raise' do
          expect do
            decoded
          end.to_not raise_error
        end

        it 'has the correct class' do
          expect(decoded['dbref']).to be_a described_class
          expect(decoded['dbref']['dbref']).to be_a BSON::Document
        end
      end
    end
  end
end
