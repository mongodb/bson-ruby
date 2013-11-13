# Copyright (C) 2009-2013 MongoDB Inc.
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

  # Defines behaviour around objects that can be encoded.
  #
  # @since 2.0.0
  module Encodable

    # A 4 byte placeholder that would be replaced by a length at a later point.
    #
    # @since 2.0.0
    PLACEHOLDER = 0.to_bson.freeze

    # Adjustment value for total number of document bytes.
    #
    # @since 2.0.0
    BSON_ADJUST = 0.freeze

    # Adjustment value for total number of string bytes.
    #
    # @since 2.0.0
    STRING_ADJUST = -4.freeze

    # Encodes BSON to raw bytes, for types that require the length of the
    # entire bytes to be present as the first word of the encoded string. This
    # includes Hash, CodeWithScope.
    #
    # @example Encode the BSON with placeholder bytes.
    #   hash.encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
    #     each do |field, value|
    #       value.to_bson(encoded)
    #     end
    #   end
    #
    # @param [ Integer ] adjust The number of bytes to adjust with.
    # @param [ String ] encoded The string to encode.
    #
    # @return [ String ] The encoded string.
    #
    # @since 2.0.0
    def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BINARY))
      pos = encoded.bytesize
      encoded << PLACEHOLDER
      yield(encoded)
      encoded << NULL_BYTE
      encoded.set_int32(pos, encoded.bytesize - pos + adjust)
      encoded
    end

    # Encodes binary data with a generic placeholder value to be written later
    # once all bytes have been written.
    #
    # @example Encode the BSON with placeholder bytes.
    #   string.encode_binary_data_with_placeholder(encoded) do |encoded|
    #     each do |field, value|
    #       value.to_bson(encoded)
    #     end
    #   end
    #
    # @param [ String ] encoded The string to encode.
    #
    # @return [ String ] The encoded string.
    #
    # @since 2.0.0
    def encode_binary_data_with_placeholder(encoded = ''.force_encoding(BINARY))
      pos = encoded.bytesize
      encoded << PLACEHOLDER
      yield(encoded)
      encoded.set_int32(pos, encoded.bytesize - pos - 5)
      encoded
    end
  end
end
