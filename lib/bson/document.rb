# Copyright (C) 2009-2019 MongoDB Inc.
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

require "yaml"

# Since we have a custom bsondoc type for yaml serialization, we need
# to ensure that it's properly deserialized when parsed.
#
# @since 2.0.0
YAML.add_builtin_type("bsondoc") do |type, value|
  BSON::Document[value.map{ |val| val.to_a.first }]
end

module BSON

  # This module provides behaviour for serializing and deserializing entire
  # BSON documents, according to the BSON specification.
  #
  # @note The specification is: document ::= int32 e_list "\x00"
  #
  # @see http://bsonspec.org/#/specification
  #
  # @since 2.0.0
  class Document < ::Hash

    # Get a value from the document for the provided key. Can use string or
    # symbol access, with string access being the faster of the two.
    #
    # @overload fetch(key)
    #   Returns a value from the hash for the given key. If the key does
    #   not exist, raises KeyError exception.
    #
    # @overload fetch(key, default)
    #   Returns a value from the hash for the given key. If the key does not
    #   exist, returns *default*.
    #
    # @overload fetch(key, &block)
    #   Returns a value from the hash for the given key. If the key does not
    #   exist, returns the value of the block called with the key.
    #
    # @example Get an element for the key.
    #   document.fetch("field")
    #
    # @example Get an element for the key by symbol with a default.
    #   document.fetch(:field, 'foo')
    #
    # @example Get an element for the key by symbol with a block default.
    #   document.fetch(:field) { |key| key.upcase }
    #
    # @param [ String, Symbol ] key The key to look up.
    # @param [ Object ] default Returned value if key does not exist.
    # @yield [key] Block returning default value for the given key.
    #
    # @return [ Object ] The found value. Raises KeyError if none found.
    #
    # @since 4.4.0
    def fetch(key, *args, &block)
      key = convert_key(key)
      super(key, *args, &block)
    end

    # Get a value from the document for the provided key. Can use string or
    # symbol access, with string access being the faster of the two.
    #
    # @example Get an element for the key.
    #   document["field"]
    #
    # @example Get an element for the key by symbol.
    #   document[:field]
    #
    # @param [ String, Symbol ] key The key to look up.
    #
    # @return [ Object ] The found value, or nil if none found.
    #
    # @since 2.0.0
    def [](key)
      super(convert_key(key))
    end

    # Set a value on the document. Will normalize symbol keys into strings.
    #
    # @example Set a value on the document.
    #   document[:test] = "value"
    #
    # @param [ String, Symbol ] key The key to update.
    # @param [ Object ] value The value to update.
    #
    # @return [ Object ] The updated value.
    #
    # @since 3.0.0
    def []=(key, value)
      super(convert_key(key), convert_value(value))
    end

    # Returns true if the given key is present in the document.  Will normalize
    # symbol keys into strings.
    #
    # @example Test if a key exists using a symbol
    #   document.has_key?(:test)
    #
    # @param [ Object ] key The key to check for.
    #
    # @return [ true, false]
    #
    # @since 4.0.0
    def has_key?(key)
      super(convert_key(key))
    end

    alias :include? :has_key?
    alias :key?     :has_key?
    alias :member?  :has_key?

    # Returns true if the given value is present in the document.  Will normalize
    # symbols into strings.
    #
    # @example Test if a key exists using a symbol
    #   document.has_value?(:test)
    #
    # @param [ Object ] value THe value to check for.
    #
    # @return [ true, false]
    #
    # @since 4.0.0
    def has_value?(value)
      super(convert_value(value))
    end

    alias :value :has_value?

    # Deletes the key-value pair and returns the value from the document
    # whose key is equal to key.
    # If the key is not found, returns the default value. If the optional code
    # block is given and the key is not found, pass in the key and return the
    # result of block.
    #
    # @example Delete a key-value pair
    #   document.delete(:test)
    #
    # @param [ Object ] key The key of the key-value pair to delete.
    #
    # @return [ Object ]
    #
    # @since 4.0.0
    def delete(key, &block)
      super(convert_key(key), &block)
    end

    # Instantiate a new Document. Valid parameters for instantiation is a hash
    # only or nothing.
    #
    # @example Create the new Document.
    #   BSON::Document.new(name: "Joe", age: 33)
    #
    # @param [ Hash ] elements The elements of the document.
    #
    # @since 3.0.0
    def initialize(elements = nil)
      super()
      (elements || {}).each_pair{ |key, value| self[key] = value }
    end

    # Merge this document with another document, returning a new document in
    # the process.
    #
    # @example Merge with another document.
    #   document.merge(name: "Bob")
    #
    # @param [ BSON::Document, Hash ] other The document/hash to merge with.
    #
    # @return [ BSON::Document ] The result of the merge.
    #
    # @since 3.0.0
    def merge(other, &block)
      dup.merge!(other, &block)
    end

    # Merge this document with another document, returning the same document in
    # the process.
    #
    # @example Merge with another document.
    #   document.merge(name: "Bob")
    #
    # @param [ BSON::Document, Hash ] other The document/hash to merge with.
    #
    # @return [ BSON::Document ] The result of the merge.
    #
    # @since 3.0.0
    def merge!(other)
      other.each_pair do |key, value|
        value = yield(convert_key(key), self[key], convert_value(value)) if block_given? && self[key]
        self[key] = value
      end
      self
    end

    alias :update :merge!

    if instance_methods.include?(:dig)
      # Retrieves the value object corresponding to the each key objects repeatedly.
      # Will normalize symbol keys into strings.
      #
      # @example Get value from nested sub-documents, handling missing levels.
      #   document # => { :key1 => { "key2" => "value"}}
      #   document.dig(:key1, :key2) # => "value"
      #   document.dig("key1", "key2") # => "value"
      #   document.dig("foo", "key2") # => nil
      #
      # @param [ Array<String, Symbol> ] *keys Keys, which constitute a "path" to the nested value.
      #
      # @return [ Object, NilClass ] The requested value or nil.
      #
      # @since 3.0.0
      def dig(*keys)
        super(*keys.map{|key| convert_key(key)})
      end
    end

    if instance_methods.include?(:slice)
      # Slices a document to include only the given keys.
      # Will normalize symbol keys into strings.
      # (this method is backported from ActiveSupport::Hash)
      #
      # @example Get a document/hash with only the `name` and `age` fields present
      #   document # => { _id: <ObjectId>, :name => 'John', :age => 30, :location => 'Earth' }
      #   document.slice(:name, 'age') # => { name: 'John', age: 30 }
      #   document.slice('name') # => { name: 'John' }
      #   document.slice(:foo) # => nil
      #
      # @param [ Array<String, Symbol> ] *keys Keys, that will be kept in the resulting document
      #
      # @return [ BSON::Document ] The document with only the selected keys
      #
      # @since 4.3.1
      def slice(*keys)
        super(*keys.map{|key| convert_key(key)})
      end
    end

    private

    def convert_key(key)
      key.to_bson_normalized_key
    end

    def convert_value(value)
      value.to_bson_normalized_value
    end
  end
end
