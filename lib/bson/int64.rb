# Copyright (C) 2013 MongoDB Inc.
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

  # Represents a $maxKey type, which compares less than any other value in the
  # specification.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Int64

    # A boolean is type 0x08 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = 18.chr.force_encoding(BINARY).freeze

    # Constant for the int 64 pack directive.
    #
    # @since 2.0.0
    PACK = Environment.ruby_18? ? "q".freeze : "q<".freeze

    # Deserialize an Integer from BSON.
    #
    # @param [ BSON ] bson The encoded int64.
    #
    # @return [ Integer ] The decoded Integer.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def self.from_bson(bson)
      from_bson_int64(bson.read(8))
    end

    private

    def self.from_bson_int64(bytes)
      bytes.unpack(PACK).first
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, self)
  end
end
