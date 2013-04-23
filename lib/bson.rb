# encoding: utf-8

# Determine if we are using JRuby or not.
#
# @example Are we running with JRuby?
#   jruby?
#
# @return [ true, false ] If JRuby is our vm.
#
# @since 2.0.0
def jruby?
  defined?(JRUBY_VERSION)
end

# Does the Ruby runtime we are using support ordered hashes?
#
# @example Does the runtime support ordered hashes?
#   ordered_hash_support?
#
# @return [ true, false ] If the runtime has ordered hashes.
#
# @since 2.0.0
def ordered_hash_support?
  jruby? || RUBY_VERSION > "1.9.1"
end

# Are we running in a ruby runtime that is version 1.8.x?
#
# @since 2.0.0
def ruby_18?
  RUBY_VERSION < "1.9"
end

# In the case where we don't have encoding, we need to monkey
# patch string to ignore the encoding directives.
#
# @since 2.0.0
if ruby_18?

  class String

    # In versions prior to 1.9 we need to ignore the encoding requests.
    #
    # @since 2.0.0
    def chr; self; end
    def force_encoding(*); self; end
    def encode(*); self; end
    def encode!(*); self; end
  end

  class EncodingError < RuntimeError; end
end

#
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

# If we have ordered hashes, the a BSON::Document is simply a hash. If we do
# not, then we need to import our custom BSON::Document implementation.
#
# @since 2.0.0
if ordered_hash_support?
  class BSON::Document < Hash; end
else
  require "bson/document"
end

# If we are using JRuby, attempt to load the Java extensions, if we are using
# MRI or Rubinius, attempt to load the C extenstions. If either of these fail,
# we revert back to a pure Ruby implementation of the Buffer class.
#
# @since 2.0.0
begin
  if jruby?
    # require "bson/NativeService.jar"
    # @todo: Durran: include when exceptions fixed.
    # org.bson.NativeService.new.basicLoad(JRuby.runtime)
  else
    require "bson/native"
  end
rescue LoadError
  $stderr.puts("BSON is using the pure Ruby implementation.")
end
