# frozen_string_literal: true
# Copyright (C) 2009-2021 MongoDB Inc.
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

  # Injects behaviour for encoding and decoding BigDecimals
  # to and from raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  module BigDecimal

    # Get the BigDecimal as encoded BSON.
    #
    # @example Get the BigDecimal as encoded BSON.
    #   BigDecimal("1").to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      BSON::Decimal128.new(to_s).to_bson
    end

    module ClassMethods

      # Deserialize the BigDecimal from raw BSON bytes.
      #
      # @example Get the BigDecimal from BSON.
      #   BigDecimal(1).from_bson(bson)
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @option options [ nil | :bson ] :mode Decoding mode to use.
      #
      # @return [ BigDecimal ] The decimal object.
      def from_bson(buffer, **options)
        Decimal128.from_bson(buffer, **options).to_big_decimal
      end
    end
  end

  # Enrich the core BigDecimal class with this module.
  #
  # @since 2.0.0
  ::BigDecimal.send(:include, BigDecimal)
  ::BigDecimal.send(:extend, BigDecimal::ClassMethods)
end
