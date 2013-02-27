# encoding: utf-8
require "bson/ext/array"
require "bson/ext/date"
require "bson/ext/false_class"
require "bson/ext/float"
require "bson/ext/hash"
require "bson/ext/integer"
require "bson/ext/nil_class"
require "bson/ext/regexp"
require "bson/ext/string"
require "bson/ext/symbol"
require "bson/ext/time"
require "bson/ext/true_class"

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
