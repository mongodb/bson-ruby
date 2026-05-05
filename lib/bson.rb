# frozen_string_literal: true
# rubocop:todo all
# Copyright (C) 2009-2020 MongoDB Inc.
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

require "bson/environment"

# The core namespace for all BSON related behaviour.
#
# @since 0.0.0
module BSON

  # Create a new object id from a string using ObjectId.from_string
  #
  # @example Create an object id from the string.
  #   BSON::ObjectId(id)
  #
  # @param [ String ] string The string to create the id from.
  #
  # @raise [ BSON::Error::InvalidObjectId ] If the provided string is invalid.
  #
  # @return [ BSON::ObjectId ] The new object id.
  #
  # @see ObjectId.from_string
  def self.ObjectId(string)
    self::ObjectId.from_string(string)
  end

  # Constant for binary string encoding.
  #
  # @since 2.0.0
  BINARY = "BINARY"

  # Constant for bson types that don't actually serialize a value.
  #
  # @since 2.0.0
  NO_VALUE = ::String.new(encoding: BINARY).freeze

  # Constant for a null byte (0x00).
  #
  # @since 2.0.0
  NULL_BYTE = ::String.new(0.chr, encoding: BINARY).freeze

  # Constant for UTF-8 string encoding.
  #
  # @since 2.0.0
  UTF8 = "UTF-8"

  # Maximum number of nested BSON documents or arrays the decoder will accept.
  # Prevents stack-overflow DoS on adversarial input. Matches libbson and the
  # Go driver's ExtJSON parser.
  MAX_NESTING_DEPTH = 200

  # Increment the per-thread BSON decode nesting depth, yield, and decrement
  # on the way out. Raises BSON::Error::BSONDecodeError if the new depth
  # exceeds MAX_NESTING_DEPTH.
  #
  # Used by the pure-Ruby decoders for Hash, Array, and Extended JSON to
  # bound recursion. The C extension applies the same cap internally.
  def self.with_nesting_depth
    depth = (Thread.current[:_bson_nesting_depth] ||= 0) + 1
    if depth > MAX_NESTING_DEPTH
      raise Error::BSONDecodeError,
            "BSON document nesting depth exceeds maximum of #{MAX_NESTING_DEPTH}"
    end
    Thread.current[:_bson_nesting_depth] = depth
    begin
      yield
    ensure
      Thread.current[:_bson_nesting_depth] = depth - 1
    end
  end
end

require "bson/config"
require "bson/error"
require "bson/registry"
require "bson/specialized"
require "bson/json"
require "bson/int32"
require "bson/int64"
require "bson/integer"
require "bson/array"
require "bson/binary"
require "bson/boolean"
require "bson/code"
require "bson/code_with_scope"
require "bson/date"
require "bson/date_time"
require "bson/db_pointer"
require "bson/decimal128"
require "bson/big_decimal"
require "bson/document"
require "bson/ext_json"
require "bson/false_class"
require "bson/float"
require "bson/hash"
require "bson/dbref"
require "bson/open_struct"
require "bson/max_key"
require "bson/min_key"
require "bson/nil_class"
require "bson/object"
require "bson/object_id"
require "bson/regexp"
require "bson/string"
require "bson/symbol"
require "bson/time"
require "bson/timestamp"
require "bson/true_class"
require "bson/undefined"
require "bson/vector"
require "bson/version"

# If we are using JRuby, attempt to load the Java extensions, if we are using
# MRI or Rubinius, attempt to load the C extensions.
#
# @since 2.0.0
begin
  if BSON::Environment.jruby?
    require "bson-ruby.jar"
    JRuby::Util.load_ext("org.bson_ruby.NativeService")
  else
    require "bson_native"
  end
rescue LoadError => e
  $stderr.puts("Failed to load the necessary extensions: #{e.class}: #{e}")
  raise
end
