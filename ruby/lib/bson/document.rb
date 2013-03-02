# encoding: utf-8
require "bson/array"
require "bson/binary"
require "bson/boolean"
require "bson/code"
require "bson/code_with_scope"
require "bson/element"
require "bson/false_class"
require "bson/float"
require "bson/int32"
require "bson/int64"
require "bson/integer"
require "bson/hash"
require "bson/max_key"
require "bson/min_key"
require "bson/nil_class"
require "bson/object_id"
require "bson/regexp"
require "bson/string"
require "bson/symbol"
require "bson/time"
require "bson/timestamp"
require "bson/true_class"

module BSON

  # This module provides behaviour for serializing and deserializing entire
  # BSON documents, according to the BSON specification.
  #
  # @note The specification is: document ::= int32 e_list "\x00"
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  module Document
    extend self

    # Serialize a document into a raw string of bytes.
    #
    # @example Serialize the document into it's raw bytes.
    #   BSON::Document.serialize({ :name => "Sid Vicious" })
    #
    # @param [ Hash ] document The document to serialize.
    #
    # @return [ String ] The raw bytes.
    #
    # @since 2.0.0
    def serialize(document)
      document.to_bson
    end
  end
end
