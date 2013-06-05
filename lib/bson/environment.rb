# Copyright (C) 2013 10gen Inc.
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

  # Provides static helper methods around determining what environment is
  # running without polluting the global namespace.
  #
  # @since 2.0.0
  module Environment
    extend self

    # Determine if we are using JRuby or not.
    #
    # @example Are we running with JRuby?
    #   Environment.jruby?
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
    #   Environment.retaining_hash_order?
    #
    # @return [ true, false ] If the runtime has ordered hashes.
    #
    # @since 2.0.0
    def retaining_hash_order?
      jruby? || RUBY_VERSION > "1.9.1"
    end

    # Are we running in a ruby runtime that is version 1.8.x?
    #
    # @example Is the ruby runtime in 1.8 mode?
    #   Environment.ruby_18?
    #
    # @return [ true, false ] If we are running in 1.8.
    #
    # @since 2.0.0
    def ruby_18?
      RUBY_VERSION < "1.9"
    end
  end
end

# In the case where we don't have encoding, we need to monkey
# patch string to ignore the encoding directives.
#
# @since 2.0.0
if BSON::Environment.ruby_18?

  # Making string in 1.8 respond like a 1.9 string, without any modifications.
  #
  # @since 2.0.0
  class String

    # Simply return the string when asking for it's character.
    #
    # @since 2.0.0
    def chr; self; end

    # Force the string to the provided encoding. NOOP.
    #
    # @since 2.0.0
    def force_encoding(*); self; end

    # Encode the string as the provided type. NOOP.
    #
    # @since 2.0.0
    def encode(*); self; end

    # Encode the string in place. NOOP.
    #
    # @since 2.0.0
    def encode!(*); self; end
  end

  # No encoding error is defined in 1.8.
  #
  # @since 2.0.0
  class EncodingError < RuntimeError; end
end
