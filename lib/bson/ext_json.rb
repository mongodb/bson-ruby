# Copyright (C) 2019 MongoDB Inc.
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

require 'json'

module BSON

  # This module contains methods for parsing Extended JSON 2.0.
  # https://github.com/mongodb/specifications/blob/master/source/extended-json.rst
  module ExtJSON

    # Parses JSON in a string into a Ruby object tree.
    #
    # There are two strategies that this method can follow. If the canonical
    # strategy is used which is the default, this method returns BSON types
    # as much as possible. This allows the resulting object tree to be
    # serialized back to extended JSON or to BSON while preserving the types.
    # The relaxed strategy, enabled by passing {emit_relaxed: true} option,
    # returns native Ruby types as much as possible which makes the resulting
    # object tree easier to work with but may lose type information.
    #
    # Please note the following aspects of this method when emitting relaxed
    # object trees:
    #
    # 1. $numberInt and $numberLong inputs produce Integer instances.
    # 2. $regularExpression inputs produce BSON Regexp instances. This may
    #    change in a future version of bson-ruby to produce Ruby Regexp
    #    instances, potentially depending on regular expression options.
    # 3. $numberDecimal inputs produce BSON Decimal128 instances. This may
    #    change in a future version of bson-ruby to produce Ruby BigDecimal
    #    instances instead.
    #
    # This method accepts canonical extended JSON, relaxed extended JSON and
    # JSON without type information as well as a mix of the above.
    #
    # @note This method uses Ruby standard library's JSON.parse method to
    # perform JSON parsing. As the JSON.parse method accepts inputs other
    # than hashes, so does this method and therefore this method can return
    # objects of any type.
    #
    # @param [ String ] str The string to parse.
    #
    # @option options [ true | false ] :emit_relaxed Whether to emit native
    #   Ruby types as much as possible
    #
    # @return [ Object ] Parsed object tree.
    module_function def parse(str, **options)
      parse_obj(::JSON.parse(str), **options)
    end

    # Transforms a Ruby object tree containing extended JSON type hashes
    # into a Ruby object tree with said hashes replaced by BSON or Ruby native
    # types.
    #
    # @example Convert extended JSON type hashes:
    #   BSON::ExtJSON.parse_obj('foo' => {'$numberLong' => '42'})
    #   => {"foo"=>#<BSON::Int64:0x000055e55f4d40f0 @value=42>}
    #
    # @example Convert a non-hash value:
    #   BSON::ExtJSON.parse_obj('$numberLong' => '42')
    #   => #<BSON::Int64:0x000055e55f4e6ed0 @value=42>
    #
    # There are two strategies that this method can follow. If the canonical
    # strategy is used which is the default, this method returns BSON types
    # as much as possible. This allows the resulting object tree to be
    # serialized back to extended JSON or to BSON while preserving the types.
    # The relaxed strategy, enabled by passing {emit_relaxed: true} option,
    # returns native Ruby types as much as possible which makes the resulting
    # object tree easier to work with but may lose type information.
    #
    # Please note the following aspects of this method when emitting relaxed
    # object trees:
    #
    # 1. $numberInt and $numberLong inputs produce Integer instances.
    # 2. $regularExpression inputs produce BSON Regexp instances. This may
    #    change in a future version of bson-ruby to produce Ruby Regexp
    #    instances, potentially depending on regular expression options.
    # 3. $numberDecimal inputs produce BSON Decimal128 instances. This may
    #    change in a future version of bson-ruby to produce Ruby BigDecimal
    #    instances instead.
    #
    # This method accepts object trees resulting from parsing canonical
    # extended JSON, relaxed extended JSON and JSON without type information
    # as well as a mix of the above.
    #
    # @note This method accepts any types as input, not just Hash instances.
    # Consequently, it can return values of any type.
    #
    # @param [ Object ] value The object tree to convert.
    #
    # @option options [ true | false ] :emit_relaxed Whether to emit native
    #   Ruby types as much as possible
    #
    # @return [ Object ] Converted object tree.
    module_function def parse_obj(value, emit_relaxed: false)
      case value
      when String, TrueClass, FalseClass, NilClass, Numeric
        value
      when Hash
        parse_hash(value, emit_relaxed: emit_relaxed)
      when Array
        value.map do |item|
          parse_obj(item, emit_relaxed: emit_relaxed)
        end
      else
        raise "Unknown value type: #{value}"
      end
    end

    private

    RESERVED_KEYS = %w(
      $oid $symbol $numberInt $numberLong $numberDouble $numberDecimal
      $binary $code $scope $timestamp $regularExpression $dbPointer
      $date $ref $id $minKey $maxKey $undefined
    ).freeze

    RESERVED_KEYS_HASH = Hash[RESERVED_KEYS.map do |key|
      [key, true]
    end].freeze

    module_function def parse_hash(hash, emit_relaxed:)
      if hash.empty?
        return {}
      end

      if hash.length == 1
        key, value = hash.first
        return case key
        when '$oid'
          ObjectId.from_string(value)
        when '$symbol'
          value.to_sym
        when '$numberInt'
          unless value.is_a?(String)
            raise "$numberInt value is of an incorrect type: #{value}"
          end
          value = value.to_i
          if emit_relaxed
            value
          else
            Int32.new(value)
          end
        when '$numberLong'
          unless value.is_a?(String)
            raise "$numberLong value is of an incorrect type: #{value}"
          end
          value = value.to_i
          if emit_relaxed
            value
          else
            Int64.new(value)
          end
        when '$numberDouble'
          # This handles string to double conversion as well as inf/-inf/nan
          unless value.is_a?(String)
            raise "Invalid $numberDouble value: #{value}"
          end
          BigDecimal(value).to_f
        when '$numberDecimal'
          # TODO consider returning BigDecimal here instead of Decimal128
          Decimal128.new(value)
        when '$binary'
          unless value.is_a?(Hash)
            raise "Invalid $binary value; #{value}"
          end
          unless value.keys.sort == %w(base64 subType)
            raise "Invalid $binary value: #{value}"
          end
          subtype = value['subType']
          unless subtype.is_a?(String)
            raise "Invalid $subType value: #{value}"
          end
          subtype = subtype.hex
          type = Binary::TYPES[subtype.chr]
          unless type
            # Requires https://jira.mongodb.org/browse/RUBY-2056
            raise NotImplementedError
          end
          Binary.new(Base64.decode64(value['base64']), type)
        when '$code'
          unless value.is_a?(String)
            raise "Invalid $code value: #{value}"
          end
          Code.new(value)
        when '$timestamp'
          unless value.keys.sort == %w(i t)
            raise "Invalid $timestamp value: #{value}"
          end
          t = value['t']
          unless t.is_a?(Integer)
            raise "Invalid t value: #{value}"
          end
          i = value['i']
          unless i.is_a?(Integer)
            raise "Invalid i value: #{value}"
          end
          Timestamp.new(t, i)
        when '$regularExpression'
          unless value.keys.sort == %w(options pattern)
            raise "Invalid $regularExpression value: #{value}"
          end
          # TODO consider returning Ruby regular expression object here
          Regexp.new(pattern, options)
        when '$dbPointer'
          raise NotImplementedError
        when '$date'
          case value
          when String
            ::Time.parse(value)
          when Hash
            unless value.keys.sort == %w($numberLong)
              raise "Invalid value for $date: #{value}"
            end
            ::Time.at(value.values.first.to_i.to_f / 1000)
          else
            raise "Invalid value for $date: #{value}"
          end
        when '$minKey'
          unless value == 1
            raise "Invalid $minKey value: #{value}"
          end
          MinKey.new
        when '$maxKey'
          unless value == 1
            raise "Invalid $maxKey value: #{value}"
          end
          MaxKey.new
        when '$undefined'
          unless value == true
            raise "Invalid $undefined value: #{value}"
          end
          Undefined.new
        else
          map_hash(hash, emit_relaxed: emit_relaxed)
        end
      end

      if hash.length == 2
        sorted_keys = hash.keys.sort
        first_key = sorted_keys.first
        return case first_key
        when '$code'
          unless sorted_keys == %w($code $scope)
            raise "Invalid $code value: #{hash}"
          end
          unless hash['$code'].is_a?(String)
            raise "Invalid $code value: #{value}"
          end
          CodeWithScope.new(hash['$code'], map_hash(hash['$scope']))
        else
          verify_no_reserved_keys(hash, emit_relaxed: emit_relaxed)
        end
      end

      verify_no_reserved_keys(hash, emit_relaxed: emit_relaxed)
    end

    module_function def verify_no_reserved_keys(hash, **options)
      if hash.length > RESERVED_KEYS.length
        if RESERVED_KEYS.any? { |key| hash.key?(key) }
          raise "Hash uses reserved keys but does not match a known type: #{hash}"
        end
      else
        if hash.keys.any? { |key| RESERVED_KEYS_HASH.key?(key) }
          raise "Hash uses reserved keys but does not match a known type: #{hash}"
        end
      end
      map_hash(hash, **options)
    end

    module_function def map_hash(hash, **options)
      ::Hash[hash.map do |key, value|
        [key, parse_obj(value, **options)]
      end]
    end
  end
end
