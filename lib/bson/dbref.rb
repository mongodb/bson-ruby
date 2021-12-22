# frozen_string_literal: true
# encoding: utf-8

# Copyright (C) 2015-2021 MongoDB Inc.
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module BSON

  # Represents a DBRef document in the database.
  class DBRef < Document
    include JSON

    # The constant for the collection reference field.
    #
    # @deprecated
    COLLECTION = '$ref'.freeze

    # The constant for the id field.
    #
    # @deprecated
    ID = '$id'.freeze

    # The constant for the database field.
    #
    # @deprecated
    DATABASE = '$db'.freeze

    # @return [ String ] collection The collection name.
    def collection
      self['$ref']
    end

    # @return [ BSON::ObjectId ] id The referenced document id.
    def id
      self['$id']
    end

    # @return [ String ] database The database name.
    def database
      self['$db']
    end

    # Get the DBRef as a JSON document
    #
    # @example Get the DBRef as a JSON hash.
    #   dbref.as_json
    #
    # @return [ Hash ] The max key as a JSON hash.
    def as_json(*args)
      {}.update(self)
    end

    # Instantiate a new DBRef.
    #
    # @example Create the DBRef.
    #   BSON::DBRef.new({'$ref' => 'users', '$id' => id, '$db' => 'database'})
    #
    # @param [ Hash ] hash the DBRef hash. It must contain $collection and $id.
    def initialize(hash)
      %w($ref $id).each do |key|
        unless hash[key]
          raise ArgumentError, "DBRef must have #{key}: #{hash}"
        end
      end

      unless hash['$ref'].is_a?(String)
        raise ArgumentError, "The value for key $ref must be a string, got: #{hash['$ref']}"
      end

      if db = hash['$db']
        unless db.is_a?(String)
          raise ArgumentError, "The value for key $db must be a string, got: #{hash['$db']}"
        end
      end

      super(hash)
    end

    # Converts the DBRef to raw BSON.
    #
    # @example Convert the DBRef to raw BSON.
    #   dbref.to_bson
    #
    # @param [ BSON::ByteBuffer ] buffer The encoded BSON buffer to append to.
    # @param [ true, false ] validating_keys Whether keys should be validated when serializing.
    #
    # @return [ String ] The raw BSON.
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      as_json.to_bson(buffer)
    end

    module ClassMethods

      # Deserialize the hash from BSON, converting to a DBRef if appropriate.
      #
      # @param [ String ] buffer The bson representing a hash.
      #
      # @return [ Hash, DBRef ] The decoded hash or DBRef.
      #
      # @see http://bsonspec.org/#/specification
      def from_bson(buffer, **options)
        decoded = super
        if decoded['$ref'] && decoded['$id']
          # We're doing implicit decoding here. If the document is an invalid
          # dbref, we should decode it as a BSON::Document.
          begin
            decoded = DBRef.new(decoded)
          rescue ArgumentError => e
          end
        end
        decoded
      end
    end
  end

  ::Hash.send(:extend, DBRef::ClassMethods)
end
