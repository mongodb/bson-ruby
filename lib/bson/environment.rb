# encoding: utf-8
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
