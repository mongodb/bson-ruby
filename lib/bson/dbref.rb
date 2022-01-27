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
    # @example Create the DBRef - hash API.
    #   BSON::DBRef.new({'$ref' => 'users', '$id' => id, '$db' => 'database'})
    #
    # @example Create the DBRef - legacy API.
    #   BSON::DBRef.new('users', id, 'database')
    #
    # @param [ Hash | String ] hash_or_collection The DBRef hash, when using
    #   the hash API. It must contain $ref and $id. When using the legacy API,
    #   this parameter must be a String containing the collection name.
    # @param [ Object ] id The object id, when using the legacy API.
    # @param [ String ] database The database name, when using the legacy API.
    def initialize(hash_or_collection, id = nil, database = nil)
      if hash_or_collection.is_a?(Hash)
        hash = hash_or_collection

        unless id.nil? && database.nil?
          raise ArgumentError, 'When using the hash API, DBRef constructor accepts only one argument'
        end
      else
        warn("BSON::DBRef constructor called with the legacy API - please use the hash API instead")

        if id.nil?
          raise ArgumentError, 'When using the legacy constructor API, id must be provided'
        end

        hash = {
          :$ref => hash_or_collection,
          :$id => id,
          :$db => database,
        }
      end

      hash = reorder_fields(hash)
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
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      as_json.to_bson(buffer, validating_keys)
    end

    private

    # Reorder the fields of the given Hash to have $ref first, $id second,
    # and $db third. The rest of the fields in the hash can come in any
    # order after that.
    #
    # @param [ Hash ] hash The input hash. Must be a valid dbref.
    #
    # @return [ Hash ] The hash with it's fields reordered.
    def reorder_fields(hash)
      hash = BSON::Document.new(hash)
      reordered = {}
      reordered['$ref'] = hash.delete('$ref')
      reordered['$id'] = hash.delete('$id')
      if db = hash.delete('$db')
        reordered['$db'] = db
      end

      reordered.update(hash)
    end
  end
end
