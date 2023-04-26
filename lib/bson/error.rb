# frozen_string_literal: true
# rubocop:todo all
module BSON
  # Base exception class for all BSON-related errors.
  class Error < StandardError
  end
end

require 'bson/error/bson_decode_error'
require 'bson/error/ext_json_parse_error'
require 'bson/error/invalid_binary_type'
require 'bson/error/invalid_dbref_argument'
require 'bson/error/invalid_decimal128_argument'
require 'bson/error/invalid_decimal128_range'
require 'bson/error/invalid_decimal128_string'
require 'bson/error/invalid_key'
require 'bson/error/invalid_object_id'
require 'bson/error/invalid_regexp_pattern'
require 'bson/error/unrepresentable_precision'
require 'bson/error/unserializable_class'
require 'bson/error/unsupported_binary_subtype'
require 'bson/error/unsupported_type'
