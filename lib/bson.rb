# encoding: utf-8
require "bson/environment"

# The core namespace for all BSON related behaviour.
#
# @since 0.0.0
module BSON

  # Constant for binary string encoding.
  #
  # @since 2.0.0
  BINARY = "BINARY".freeze

  # Constant for bson types that don't actually serialize a value.
  #
  # @since 2.0.0
  NO_VALUE = "".force_encoding(BINARY).freeze

  # Constant for a null byte (0x00).
  #
  # @since 2.0.0
  NULL_BYTE = 0.chr.force_encoding(BINARY).freeze

  # Constant for UTF-8 string encoding.
  #
  # @since 2.0.0
  UTF8 = "UTF-8".freeze
end

require "bson/registry"
require "bson/specialized"
require "bson/json"
require "bson/int32"
require "bson/int64"
require "bson/integer"
require "bson/encodable"
require "bson/array"
require "bson/binary"
require "bson/boolean"
require "bson/code"
require "bson/code_with_scope"
require "bson/document"
require "bson/false_class"
require "bson/float"
require "bson/hash"
require "bson/max_key"
require "bson/min_key"
require "bson/nil_class"
require "bson/object_id"
require "bson/regexp"
require "bson/string"
require "bson/symbol"
require "bson/time"
require "bson/timestamp"
require "bson/true_class"
require "bson/undefined"
require "bson/version"

# If we are using JRuby, attempt to load the Java extensions, if we are using
# MRI or Rubinius, attempt to load the C extenstions. If either of these fail,
# we revert back to a pure Ruby implementation of the Buffer class.
#
# @since 2.0.0
begin
  if BSON::Environment.jruby?
    require "bson-ruby.jar"
    org.bson.NativeService.new.basicLoad(JRuby.runtime)
  else
    require "native"
  end
rescue LoadError
  $stderr.puts("BSON is using the pure Ruby implementation.")
end
