# Copyright (C) 2009-2019 MongoDB Inc.
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

  class DbPointer
    include JSON

    BSON_TYPE = 0x0C.chr.force_encoding(BINARY).freeze

    def initialize(ref, id)
      @ref = ref
      @id = id
    end

    attr_reader :ref
    attr_reader :id

    def ==(other)
      return false unless other.is_a?(DbPointer)
      ref == other.ref && id == other.id
    end

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

    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      buffer.put_string(ref)
      id.to_bson(buffer, validating_keys)
      buffer
    end

    def self.from_bson(buffer, **options)
      new(buffer.get_string, ObjectId.from_bson(buffer, **options))
    end

    # Register this type when the module is loaded.
    Registry.register(BSON_TYPE, self)
  end
end
