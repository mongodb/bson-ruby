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

  # Injects behaviour for encoding and decoding floating point values
  # to and from raw bytes as specified by the BSON spec.
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Float

    # A floating point is type 0x01 in the BSON spec.
    #
    # @since 2.0.0
    BSON_TYPE = ::String.new(1.chr, encoding: BINARY).freeze

    # The pack directive is for 8 byte floating points.
    #
    # @since 2.0.0
    PACK = "E"

    # Get the floating point as encoded BSON.
    #
    # @example Get the floating point as encoded BSON.
    #   1.221311.to_bson
    #
    # @return [ BSON::ByteBuffer ] The buffer with the encoded object.
    #
    # @see http://bsonspec.org/#/specification
    #
    # @since 2.0.0
    def to_bson(buffer = ByteBuffer.new, validating_keys = Config.validating_keys?)
      buffer.put_double(self)
    end

    # Converts this object to a representation directly serializable to
    # Extended JSON (https://github.com/mongodb/specifications/blob/master/source/extended-json.rst).
    #
    # This method returns the float itself if relaxed representation is
    # requested and the value is finite, otherwise a $numberDouble hash.
    #
    # @option opts [ nil | :relaxed | :legacy ] :mode Serialization mode
    #   (default is canonical extended JSON)
    #
    # @return [ Hash | Float ] The extended json representation.
    def as_extended_json(**options)
      if infinite? == 1
        { '$numberDouble' => 'Infinity' }
      elsif infinite? == -1
        { '$numberDouble' => '-Infinity' }
      elsif nan?
        { '$numberDouble' => 'NaN' }
      elsif options[:mode] == :relaxed || options[:mode] == :legacy
        self
      elsif BSON::Environment.jruby? && abs > 1e15
        # Hack to make bson corpus spec tests pass.
        # JRuby serializes -1.2345678901234568e+18 as
        # -1234567890123456770.0, which is valid but differs from MRI
        # serialization. Extended JSON spec does not define precise
        # stringification of floats.
        # https://jira.mongodb.org/browse/SPEC-1536
        { '$numberDouble' => ('%.17g' % to_s).upcase }
      else
        { '$numberDouble' => to_s.upcase }
      end
    end

    module ClassMethods

      # Deserialize an instance of a Float from a BSON double.
      #
      # @param [ ByteBuffer ] buffer The byte buffer.
      #
      # @option options [ nil | :bson ] :mode Decoding mode to use.
      #
      # @return [ Float ] The decoded Float.
      #
      # @see http://bsonspec.org/#/specification
      #
      # @since 2.0.0
      def from_bson(buffer, **options)
        buffer.get_double
      end
    end

    # Register this type when the module is loaded.
    #
    # @since 2.0.0
    Registry.register(BSON_TYPE, ::Float)
  end

  # Enrich the core Float class with this module.
  #
  # @since 2.0.0
  ::Float.send(:include, Float)
  ::Float.send(:extend, Float::ClassMethods)
end
