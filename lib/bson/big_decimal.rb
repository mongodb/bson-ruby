# frozen_string_literal: true
# rubocop:todo all
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

    # BigDecimals are serialized as Decimal128s under the hood. A Decimal128
    # is type 0x13 in the BSON spec.
    BSON_TYPE = ::String.new(19.chr, encoding: BINARY).freeze

    # Get the BigDecimal as encoded BSON.
    #
    # @example Get the BigDecimal as encoded BSON.
    #   BigDecimal("1").to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    def to_bson(buffer = ByteBuffer.new)
      BSON::Decimal128.new(to_s).to_bson(buffer)
    end

    # Get the BSON type for BigDecimal. This is the same BSON type as
    # BSON::Decimal128.
    def bson_type
      BSON_TYPE
    end

    module ClassMethods

      # Deserialize the BigDecimal from raw BSON bytes. If the :mode option
      # is set to BSON, this will return a BSON::Decimal128
      #
      # @example Get the BigDecimal from BSON.
      #   BigDecimal.from_bson(bson)
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @option options [ nil | :bson ] :mode Decoding mode to use.
      #
      # @return [ BigDecimal | BSON::Decimal128 ] The decimal object.
      def from_bson(buffer, **options)
        dec128 = Decimal128.from_bson(buffer, **options)
        if options[:mode] == :bson
          dec128
        else
          dec128.to_d
        end
      end
    end

    # Register this type when the module is loaded.
    Registry.register(BSON_TYPE, ::BigDecimal)
  end

  # Enrich the core BigDecimal class with this module.
  ::BigDecimal.send(:include, BigDecimal)
  ::BigDecimal.send(:extend, BigDecimal::ClassMethods)
end
