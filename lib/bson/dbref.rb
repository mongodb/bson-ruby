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
    # @param [ Hash ] hash the DBRef hash. It must contain $ref and $id.
    def initialize(hash)
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

      super
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
