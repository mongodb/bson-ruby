# Copyright (C) 2016 MongoDB Inc.
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

  # Provides configuration options for the BSON library.
  #
  # @since 4.1.0
  module Config
    extend self

    # Set the configuration option for BSON to validate keys or not.
    #
    # @example Set the config option.
    #   BSON::Config.validating_keys = true
    #
    # @param [ true, false ] value The value to set.
    #
    # @return [ true, false ] The value.
    #
    # @since 4.1.0
    def validating_keys=(value)
      @validating_keys = value
    end

    # Returns true if BSON will validate the document keys on serialization to
    # determine if they contain invalid MongoDB values. Invalid keys start with
    # '$' or contain a '.' in them.
    #
    # @example Is BSON validating keys?
    #   BSON::Config.validating_keys?
    #
    # @return [ true, false ] If BSON is validating keys?
    #
    # @since 4.1.0
    def validating_keys?
      !!@validating_keys
    end
  end
end
