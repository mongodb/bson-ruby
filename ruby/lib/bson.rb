# encoding: utf-8
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
require "bson/document"
require "bson/version"

# Determine if we are using JRuby or not.
#
# @example Are we running with JRuby?
#   jruby?
#
# @return [ true, false ] If JRuby is our vm.
#
# @since 2.0.0
def jruby?
  RUBY_ENGINE == "jruby"
end

# If we are using JRuby, attempt to load the Java extensions, if we are using
# MRI or Rubinius, attempt to load the C extenstions. If either of these fail,
# we revert back to a pure Ruby implementation of the Buffer class.
#
# @since 2.0.0
begin
  if jruby?
    # Java extenstions would be packaged in a native.jar with a Java Buffer
    # implementation.
    require "bson/native.jar"
  else
    # C extensions would be packed in a bundle called native with a C buffer
    # implementation.
    require "bson/native"
  end
rescue LoadError
  $stderr.puts("BSON is using the pure Ruby implementation.")
end
