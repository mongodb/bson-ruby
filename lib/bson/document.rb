# Copyright (C) 2013 10gen Inc.
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
    # symbol access, but the fastest will be to always provide a key that is of
    # the same type as the stored keys.
    #
    # @example Get an element for the key.
    #   document["field"]
    #
    # @example Get an element for the key by symbol.
    #   document[:field]
    #
    # @param [ String, Symbol ] key The key to lookup.
    #
    # @return [ Object ] The found value, or nil if none found.
    #
    # @since 2.0.0
    def [](key)
      super(key) || super(key.to_s)
    end

    # If we have ordered hashes, the a BSON::Document is simply a hash. If we do
    # not, then we need to import our custom BSON::Document implementation.
    #
    # @since 2.0.0
    unless Environment.retaining_hash_order?

      # Message for argument error when providing bad arguments to [].
      #
      # @since 2.0.0
      ARG_ERROR = "An even number of arguments must be passed to BSON::Document[]."

      # Sets a value for the provided key.
      #
      # @example Set the value in the document.
      #   document[:name] = "Sid"
      #
      # @param [ Object ] key The name of the key.
      # @param [ Object ] value The value for the key.
      #
      # @return [ Object ] The passed in value.
      #
      # @since 2.0.0
      def []=(key, value)
        order.push(key) unless has_key?(key)
        super
      end

      # Clear out all elements in the document.
      #
      # @example Clear out all elements.
      #   document.clear
      #
      # @return [ BSON::Document ] The empty document.
      #
      # @since 2.0.0
      def clear
        super
        order.clear
        self
      end

      # Delete a value from the document for the provided key.
      #
      # @example Delete a value from the document.
      #   document.delete(:name)
      #
      # @param [ Object ] key The key to delete for.
      #
      # @return [ Object ] The deleted value.
      #
      # @since 2.0.0
      def delete(key)
        if has_key?(key)
          order.delete_at(order.index(key))
        end
        super
      end

      # Delete each key/value pair in the document for which the provided block
      # returns true.
      #
      # @example Delete each for when the block is true.
      #   document.delete_if do |key, value|
      #     value == 1
      #   end
      #
      # @return [ BSON::Document ] The document.
      #
      # @since 2.0.0
      def delete_if
        super
        synchronize!
        self
      end
      alias :reject! :delete_if

      # Iterate over each element of the document in insertion order and yield
      # the key and value.
      #
      # @example Iterate over the document.
      #   document.each do |key, value|
      #     #...
      #   end
      #
      # @return [ BSON::Document ] The document if a block was given, otherwise
      #   an enumerator.
      #
      # @since 2.0.0
      def each
        if block_given?
          order.each{ |key| yield([ key, self[key]]) }
          self
        else
          to_enum(:each)
        end
      end

      # Iterate over each key in the document in insertion order and yield the
      # key.
      #
      # @example Iterate over the keys.
      #   document.each_key do |key|
      #     #...
      #   end
      #
      # @return [ BSON::Document ] The document if a block was given, otherwise
      #   an enumerator.
      #
      # @since 2.0.0
      def each_key
        if block_given?
          order.each{ |key| yield(key) }
          self
        else
          to_enum(:each_key)
        end
      end

      # Iterate over each value in the document in insertion order and yield the
      # value.
      #
      # @example Iterate over the values.
      #   document.each_value do |value|
      #     #...
      #   end
      #
      # @return [ BSON::Document ] The document if a block was given, otherwise
      #   an enumerator.
      #
      # @since 2.0.0
      def each_value
        if block_given?
          order.each{ |key| yield(self[key]) }
          self
        else
          to_enum(:each_value)
        end
      end

      # Iterate over each element of the document in insertion order and yield
      # the key and value.
      #
      # @example Iterate over the document.
      #   document.each_pair do |key, value|
      #     #...
      #   end
      #
      # @return [ BSON::Document ] The document if a block was given, otherwise
      #   an enumerator.
      #
      # @since 2.0.0
      def each_pair
        if block_given?
          order.each{ |key| yield([ key, self[key]]) }
          self
        else
          to_enum(:each_pair)
        end
      end

      # Encode the document with the provided coder.
      #
      # @example Encode the document with the coder.
      #   document.encode_with(coder)
      #
      # @param [ Object ] coder The coder.
      #
      # @return [ String ] The encoded document.
      #
      # @since 2.0.0
      def encode_with(coder)
        coder.represent_seq("!bsondoc", map{ |key, value| { key => value }})
      end

      # Get all the keys in the document, in order.
      #
      # @example Get all the keys in the document.
      #   document.keys
      #
      # @return [ Array<Object> ] The ordered keys.
      #
      # @since 2.0.0
      def keys
        order.dup
      end

      # Instantiate a new Document.
      #
      # @example Instantiate an empty new document.
      #   BSON::Document.new
      #
      # @since 2.0.0
      def initialize(*args, &block)
        super
        @order = []
      end

      # Inspect the contents of the document.
      #
      # @example Inspect the document.
      #   document.inspect
      #
      # @return [ String ] The inspection string.
      #
      # @since 2.0.0
      def inspect
        "#<BSON::Document #{super}>"
      end

      # Invert the document - reverses the order of all key/value pairs and
      # returns a new document.
      #
      # @example Invert the document.
      #   document.invert
      #
      # @return [ BSON::Document ] The inverted document.
      #
      # @since 2.0.0
      def invert
        Document[to_a.map!{ |pair| pair.reverse }]
      end

      # Merge a document into this document. Will overwrite any existing keys and
      # add potential new ones. This returns a new document instead of merging in
      # place.
      #
      # @example Merge the document into this document.
      #   document.merge(other_document)
      #
      # @param [ BSON::Document ] other The document to merge in.
      #
      # @return [ BSON::Document ] A newly merged document.
      #
      # @since 2.0.0
      def merge(other, &block)
        dup.merge!(other, &block)
      end

      # Merge a document into this document. Will overwrite any existing keys and
      # add potential new ones.
      #
      # @example Merge the document into this document.
      #   document.merge!(other_document)
      #
      # @param [ BSON::Document ] other The document to merge in.
      #
      # @return [ BSON::Document ] The document.
      #
      # @since 2.0.0
      def merge!(other)
        if block_given?
          other.each do |key, value|
            self[key] = key?(key) ? yield(key, self[key], value) : value
          end
        else
          other.each{ |key, value| self[key] = value }
        end
        self
      end
      alias :update :merge!

      # Delete each key/value pair in the document for which the provided block
      # returns true. This returns a new document instead of modifying in place.
      #
      # @example Delete each for when the block is true.
      #   document.reject do |key, value|
      #     value == 1
      #   end
      #
      # @return [ BSON::Document ] The new document.
      #
      # @since 2.0.0
      def reject(&block)
        dup.reject!(&block)
      end

      # Replace this document with the other document.
      #
      # @example Replace the contents of this document with the other.
      #   document.replace(other_document)
      #
      # @param [ BSON::Document ] other The other document.
      #
      # @return [ BSON::Document ] The document replaced.
      #
      # @since 2.0.0
      def replace(other)
        super
        @order = other.keys
        self
      end

      # Shift the document by popping off the first key/value pair in the
      # document.
      #
      # @example Shift the document.
      #   document.shift
      #
      # @return [ Array<Object, Object> ] The first key/value pair.
      #
      # @since 2.0.0
      def shift
        key = order.first
        value = delete(key)
        [ key, value ]
      end

      alias :select :find_all

      # Get the document as an array. This returns a multi-dimensional array
      # where each element is a [ key, value ] pair in the insertion order.
      #
      # @example Get the document as an array.
      #   document.to_a
      #
      # @return [ Array<Array<Object, Object>> ] The pairs in insertion order.
      #
      # @since 2.0.0
      def to_a
        order.map{ |key| [ key, self[key] ]}
      end

      # Convert this document to a hash. Since a document is simply an ordered
      # hash we return self.
      #
      # @example Get the document as a hash.
      #   document.to_hash
      #
      # @return [ BSON::Document ] The document.
      #
      # @since 2.0.0
      def to_hash
        self
      end

      # Convert the document to yaml.
      #
      # @example Convert the document to yaml.
      #   document.to_yaml
      #
      # @param [ Hash ] options The yaml options.
      #
      # @return [ String ] The document as yaml.
      #
      # @since 2.0.0
      def to_yaml(options = {})
        if YAML.const_defined?(:ENGINE) && !YAML::ENGINE.syck?
          return super
        end
        YAML.quick_emit(self, options) do |out|
          out.seq(taguri) do |seq|
            each{ |key, value| seq.add(key => value) }
          end
        end
      end

      # Get the custom yaml type for the document.
      #
      # @example Get the yaml type.
      #   document.to_yaml_type
      #
      # @return [ String ] "!bsondoc".
      #
      # @since 2.0.0
      def to_yaml_type
        "!bsondoc"
      end

      # Get all the values in the document, by order of insertion.
      #
      # @example Get all the values in the document.
      #   document.values
      #
      # @return [ Array<Object> ] The ordered values.
      #
      # @since 2.0.0
      def values
        order.map{ |key| self[key] }
      end

      class << self

        # Create a new document given the provided arguments. The args can either
        # be empty in order to instantiate an empty document, or an array of
        # key/value pairs in the order that they should remain in.
        #
        # @example Create a new empty document.
        #   BSON::Document[]
        #
        # @example Create a new document with the provided elements.
        #   BSON::Document[1, 2, 3, 4]
        #
        # @example Create a new document with key/value array pairs.
        #   BSON::Document[[ 1, 2 ], [ 3, 4 ]]
        #
        # @param [ Array<Object> ] args The key/value pairs.
        #
        # @return [ BSON::Document ] The new document.
        #
        # @since 2.0.0
        def [](*args)
          if (args.length == 1 && args.first.is_a?(Array))
            return document_from_pairs(args)
          end
          raise ArgumentError.new(ARG_ERROR) unless (args.size % 2 == 0)
          document_from_args(args)
        end

        private

        # Returns a document that will be generated from an array of [ key, value ]
        # array pairs.
        #
        # @api private
        #
        # @example Initialize a document from array pairs.
        #   BSON::Document[[ 1, 2 ], [ 3, 4 ]]
        #
        # @param [ Array ] pairs The key/value pairs.
        #
        # @since 2.0.0
        #
        # @return [ BSON::Document ] The document.
        def document_from_pairs(pairs)
          document = new
          pairs.first.each do |pair|
            next unless (pair.is_a?(Array))
            document[pair[0]] = pair[1]
          end
          return document
        end

        # Returns a document that will be generated from an even number of
        # individual arguments.
        #
        # @api private
        #
        # @example Initialize a document from args.
        #   BSON::Document[1, 2, 3, 4]
        #
        # @param [ Array ] args The arguments.
        #
        # @return [ BSON::Document ] The document.
        #
        # @since 2.0.0
        def document_from_args(args)
          document = new
          args.each_with_index do |val, ind|
            next if (ind % 2 != 0)
            document[val] = args[ind + 1]
          end
          document
        end
      end

      private

      # @!attribute order
      #   @api private
      #   @return [ Array<String> ] The document keys in order.
      #   @since 2.0.0
      attr_reader :order

      # Initialize a copy of the document for use with clone or dup.
      #
      # @api private
      #
      # @example Clone the document.
      #   document.clone
      #
      # @param [ Object ] other The original copy.
      #
      # @since 2.0.0
      def initialize_copy(other)
        super
        @order = other.keys
      end

      # Ensure that the ordered keys are the same entries as the internal keys.
      #
      # @api private
      #
      # @example Synchronize the keys.
      #   document.synchronize!
      #
      # @return [ Array<Object> ] The keys.
      #
      # @since 2.0.0
      def synchronize!
        order.reject!{ |key| !has_key?(key) }
      end
    end
  end
end
