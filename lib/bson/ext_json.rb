# frozen_string_literal: true
# Copyright (C) 2019-2020 MongoDB Inc.
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
    # @option options [ nil | :bson ] :mode Which types to emit
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
    # @option options [ nil | :bson ] :mode Which types to emit
    #
    # @return [ Object ] Converted object tree.
    module_function def parse_obj(value, **options)
      # TODO implement :ruby and :ruby! modes
      unless [nil, :bson].include?(options[:mode])
        raise ArgumentError, "Invalid value for :mode option: #{options[:mode].inspect}"
      end

      case value
      when String, TrueClass, FalseClass, NilClass, Numeric
        value
      when Hash
        parse_hash(value, **options)
      when Array
        value.map do |item|
          parse_obj(item, **options)
        end
      else
        raise Error::ExtJSONParseError, "Unknown value type: #{value}"
      end
    end

    private

    RESERVED_KEYS = %w(
      $oid $symbol $numberInt $numberLong $numberDouble $numberDecimal
      $binary $code $scope $timestamp $regularExpression $dbPointer
      $date $minKey $maxKey $undefined
    ).freeze

    RESERVED_KEYS_HASH = Hash[RESERVED_KEYS.map do |key|
      [key, true]
    end].freeze

    module_function def parse_hash(hash, **options)
      if hash.empty?
        return {}
      end

      if dbref?(hash)
        # Legacy dbref handling.
        # Note that according to extended json spec, only hash values (but
        # not the top-level BSON document itself) may be of type "dbref".
        # This code applies to both hash values and the hash overall; however,
        # since we do not have DBRef as a distinct type, applying the below
        # logic to top level hashes doesn't cause harm.
        hash = hash.dup
        ref = hash.delete('$ref')
        # $id, if present, can be anything
        id = hash.delete('$id')
        if id.is_a?(Hash)
          id = parse_hash(id)
        end
        # Preserve $id value as it was, do not convert either to ObjectId
        # or to a string. But if the value was in {'$oid' => ...} format,
        # the value is converted to an ObjectId instance so that
        # serialization to BSON later on works correctly.
        out = {'$ref' => ref, '$id' => id}
        if hash.key?('$db')
          # $db must always be a string, if provided
          out['$db'] = hash.delete('$db')
        end
        return out.update(parse_hash(hash))
      end

      if hash.length == 1
        key, value = hash.first
        return case key
        when '$oid'
          ObjectId.from_string(value)
        when '$symbol'
          Symbol::Raw.new(value)
        when '$numberInt'
          unless value.is_a?(String)
            raise Error::ExtJSONParseError, "$numberInt value is of an incorrect type: #{value}"
          end
          value.to_i
        when '$numberLong'
          unless value.is_a?(String)
            raise Error::ExtJSONParseError, "$numberLong value is of an incorrect type: #{value}"
          end
          value = value.to_i
          if options[:mode] != :bson
            value
          else
            Int64.new(value)
          end
        when '$numberDouble'
          # This handles string to double conversion as well as inf/-inf/nan
          unless value.is_a?(String)
            raise Error::ExtJSONParseError, "Invalid $numberDouble value: #{value}"
          end
          BigDecimal(value).to_f
        when '$numberDecimal'
          # TODO consider returning BigDecimal here instead of Decimal128
          Decimal128.new(value)
        when '$binary'
          unless value.is_a?(Hash)
            raise Error::ExtJSONParseError, "Invalid $binary value: #{value}"
          end
          unless value.keys.sort == %w(base64 subType)
            raise Error::ExtJSONParseError, "Invalid $binary value: #{value}"
          end
          encoded_value = value['base64']
          unless encoded_value.is_a?(String)
            raise Error::ExtJSONParseError, "Invalid base64 value in $binary: #{value}"
          end
          subtype = value['subType']
          unless subtype.is_a?(String)
            raise Error::ExtJSONParseError, "Invalid subType value in $binary: #{value}"
          end
          create_binary(encoded_value, subtype)

        when '$uuid'
          unless /\A[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}\z/.match(value)
            raise Error::ExtJSONParseError, "Invalid $uuid value: #{value}"
          end

          return Binary.from_uuid(value)

        when '$code'
          unless value.is_a?(String)
            raise Error::ExtJSONParseError, "Invalid $code value: #{value}"
          end
          Code.new(value)
        when '$timestamp'
          unless value.keys.sort == %w(i t)
            raise Error::ExtJSONParseError, "Invalid $timestamp value: #{value}"
          end
          t = value['t']
          unless t.is_a?(Integer)
            raise Error::ExtJSONParseError, "Invalid t value: #{value}"
          end
          i = value['i']
          unless i.is_a?(Integer)
            raise Error::ExtJSONParseError, "Invalid i value: #{value}"
          end
          Timestamp.new(t, i)
        when '$regularExpression'
          unless value.keys.sort == %w(options pattern)
            raise Error::ExtJSONParseError, "Invalid $regularExpression value: #{value}"
          end
          # TODO consider returning Ruby regular expression object here
          create_regexp(value['pattern'], value['options'])
        when '$dbPointer'
          unless value.keys.sort == %w($id $ref)
            raise Error::ExtJSONParseError, "Invalid $dbPointer value: #{value}"
          end
          DbPointer.new(value['$ref'], parse_hash(value['$id']))
        when '$date'
          case value
          when String
            ::Time.parse(value).utc
          when Hash
            unless value.keys.sort == %w($numberLong)
              raise Error::ExtJSONParseError, "Invalid value for $date: #{value}"
            end
            sec, msec = value.values.first.to_i.divmod(1000)
            ::Time.at(sec, msec*1000).utc
          else
            raise Error::ExtJSONParseError, "Invalid value for $date: #{value}"
          end
        when '$minKey'
          unless value == 1
            raise Error::ExtJSONParseError, "Invalid $minKey value: #{value}"
          end
          MinKey.new
        when '$maxKey'
          unless value == 1
            raise Error::ExtJSONParseError, "Invalid $maxKey value: #{value}"
          end
          MaxKey.new
        when '$undefined'
          unless value == true
            raise Error::ExtJSONParseError, "Invalid $undefined value: #{value}"
          end
          Undefined.new
        else
          map_hash(hash, **options)
        end
      end

      if hash.length == 2
        sorted_keys = hash.keys.sort
        first_key = sorted_keys.first
        last_key = sorted_keys.last

        if first_key == '$code'
          unless sorted_keys == %w($code $scope)
            raise Error::ExtJSONParseError, "Invalid $code value: #{hash}"
          end
          unless hash['$code'].is_a?(String)
            raise Error::ExtJSONParseError, "Invalid $code value: #{value}"
          end

          return CodeWithScope.new(hash['$code'], map_hash(hash['$scope']))
        end

        if first_key == '$binary'
          unless sorted_keys == %w($binary $type)
            raise Error::ExtJSONParseError, "Invalid $binary value: #{hash}"
          end
          unless hash['$binary'].is_a?(String)
            raise Error::ExtJSONParseError, "Invalid $binary value: #{value}"
          end
          unless hash['$type'].is_a?(String)
            raise Error::ExtJSONParseError, "Invalid $binary subtype: #{hash['$type']}"
          end

          return create_binary(hash['$binary'], hash['$type'])
        end

        if last_key == '$regex'
          unless sorted_keys == %w($options $regex)
            raise Error::ExtJSONParseError, "Invalid $regex value: #{hash}"
          end

          if hash['$regex'].is_a?(Hash)
            return {
              '$regex' => parse_hash(hash['$regex']),
              '$options' => hash['$options']
            }
          end

          unless hash['$regex'].is_a?(String)
            raise Error::ExtJSONParseError, "Invalid $regex pattern: #{hash['$regex']}"
          end
          unless hash['$options'].is_a?(String)
            raise Error::ExtJSONParseError, "Invalid $regex options: #{hash['$options']}"
          end

          return create_regexp(hash['$regex'], hash['$options'])
        end

        verify_no_reserved_keys(hash, **options)
      end

      verify_no_reserved_keys(hash, **options)
    end

    module_function def verify_no_reserved_keys(hash, **options)
      if hash.length > RESERVED_KEYS.length
        if RESERVED_KEYS.any? { |key| hash.key?(key) }
          raise Error::ExtJSONParseError, "Hash uses reserved keys but does not match a known type: #{hash}"
        end
      else
        if hash.keys.any? { |key| RESERVED_KEYS_HASH.key?(key) }
          raise Error::ExtJSONParseError, "Hash uses reserved keys but does not match a known type: #{hash}"
        end
      end
      map_hash(hash, **options)
    end

    module_function def map_hash(hash, **options)
      ::Hash[hash.map do |key, value|
        if (key.is_a?(String) || key.is_a?(Symbol)) && key.to_s.include?(NULL_BYTE)
          raise Error::ExtJSONParseError, "Hash key cannot contain a null byte: #{key}"
        end
        [key, parse_obj(value, **options)]
      end]
    end

    module_function def create_binary(encoded_value, encoded_subtype)
      subtype = encoded_subtype.hex
      type = Binary::TYPES[subtype.chr]
      unless type
        # Requires https://jira.mongodb.org/browse/RUBY-2056
        raise NotImplementedError, "Binary subtype #{encoded_subtype} is not currently supported"
      end
      Binary.new(Base64.decode64(encoded_value), type)
    end

    module_function def create_regexp(pattern, options)
      Regexp::Raw.new(pattern, options)
    end

    module_function def dbref?(hash)
      if db = hash.key?('$db')
        unless db.is_a?(String)
          return false
        end
      end
      return hash['$ref']&.is_a?(String) && hash.key?('$id')
    end
  end
end
