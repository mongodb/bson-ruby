# frozen_string_literal: true

# Copyright (C) 2025-present MongoDB Inc.
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
  # Vector of numbers along with metadata for binary interoperability.
  class Vector < ::Array
    # @return [ Integer ] The data type stored in the vector.
    attr_reader :dtype

    # @return [ Integer ]  The number of bits in the final byte that are to
    # be ignored when a vector element's size is less than a byte
    # and the length of the vector is not a multiple of 8.
    attr_reader :padding

    # @return [ BSON::ByteBuffer ] The data in the vector.
    def data
      self
    end

    # @param [ ::Array ] data The data to initialize the vector with.
    # @param [ Integer ] dtype The data type of the vector.
    # @param [ Integer ] padding The number of bits in the final byte that are to
    # be ignored when a vector element's size is less than a byte
    # and the length of the vector is not a multiple of 8.
    def initialize(data, dtype, padding = 0)
      @dtype = dtype
      @padding = padding
      super(data.dup)
    end
  end
end
