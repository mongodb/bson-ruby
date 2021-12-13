# frozen_string_literal: true
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
      @jruby ||= defined?(JRUBY_VERSION)
    end

    # Determine if we are using Ruby version 1.9.
    #
    # @example Are we running with Ruby version 1.9?
    #   Environment.ruby_1_9?
    #
    # @return [ true, false ] If the Ruby version is 1.9.
    #
    # @since 4.2.0
    # @deprecated
    def ruby_1_9?
      @ruby_1_9 ||= RUBY_VERSION < '2.0.0'
    end
  end
end
