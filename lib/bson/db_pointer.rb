# frozen_string_literal: true
# Copyright (C) 2020 MongoDB Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module BSON

  # Injects behaviour for encoding and decoding DBPointer values to and from
  # raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  class DbPointer
    include JSON

    # A DBPointer is type 0x0C in the BSON spec.
    BSON_TYPE = ::String.new(0x0C.chr, encoding: BINARY).freeze

    # Create a new DBPointer object.
    #
    # @param [ String ] ref The database collection name.
    # @param [ BSON::ObjectId ] id The DBPointer id.
    def initialize(ref, id)
      @ref = ref
      @id = id
    end

    # Return the collection name.
    #
    # @return [ String ] The database collection name.
    attr_reader :ref

    # Return the DbPointer's id.
    #
    # @return [ BSON::ObjectId ] The id of the DbPointer instance
    attr_reader :id

    # Determine if this DBPointer object is equal to another object.
    #
    # @param [ Object ] other The object to compare against.
    #
    # @return [ true | false ] If the objects are equal
    def ==(other)
      return false unless other.is_a?(DbPointer)
      ref == other.ref && id == other.id
    end

    # Get the DBPointer as JSON hash data
    #
    # @return [ Hash ] The DBPointer as a JSON hash.
    #
    # @deprecated Use as_extended_json instead.
    def as_json(*args)
      as_extended_json
    end

    # Converts this object to a representation directly serializable to
    # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
    #
    # @option options [ true | false ] :relaxed Whether to produce relaxed
    #   extended JSON representation.
    #
    # @return [ Hash ] The extended json representation.
    def as_extended_json(**options)
      {'$dbPointer' => { "$ref" => ref, '$id' => id.as_extended_json }}
    end

    # Encode the DBPointer.
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      buffer.put_string(ref)
      id.to_bson(buffer, validating_keys)
      buffer
    end

    # Deserialize a DBPointer from BSON.
    #
    # @param [ ByteBuffer ] buffer The byte buffer.
    # @param [ Hash ] options
    #
    # @option options [ nil | :bson ] :mode Decoding mode to use.
    #
    # @return [ BSON::DbPointer ] The decoded DBPointer.
    #
    # @see http://bsonspec.org/#/specification
    def self.from_bson(buffer, **options)
      ref = buffer.get_string
      id = if options.empty?
        ObjectId.from_bson(buffer)
      else
        ObjectId.from_bson(buffer, **options)
      end
      new(ref, id)
    end

    # Register this type when the module is loaded.
    Registry.register(BSON_TYPE, self)
  end
end
