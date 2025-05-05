# frozen_string_literal: true

# rubocop:todo all
require 'runners/common_driver'

module BSON
  module BinaryVector
    class Spec < CommonDriver::Spec
      def initialize(file)
        super
        @valid = @invalid = nil
      end

      def tests
        @spec['tests'].collect do |test|
          BSON::BinaryVector::Test.new(self, test)
        end
      end

      def valid_tests
        tests.select(&:valid?)
      end

      def invalid_tests
        tests.reject(&:valid?)
      end
    end

    class Test

      attr_reader :canonical_bson, :description, :dtype, :padding, :vector

      def initialize(spec, test)
        @spec = spec
        @description = test['description']
        @valid = test['valid']
        @vector = ExtJSON.parse_obj(test['vector'])
        @dtype_hex = test['dtype_hex']
        @dtype_alias = test['dtype_alias']
        @dtype = @dtype_alias.downcase.to_sym
        @padding = test['padding']
        @canonical_bson = test['canonical_bson']
      end

      def valid?
        @valid
      end

      def document_from_canonical_bson
        bson_bytes = decode_hex(@canonical_bson)
        buffer = BSON::ByteBuffer.new(bson_bytes)
        BSON::Document.from_bson(buffer)

      end

      def canonical_bson_from_document(use_vector_type: false, validate_vector_data: false)
        args = if use_vector_type
                 [ BSON::Vector.new(@vector, @dtype, @padding) ]
               else
                 [ @vector, @dtype, @padding ]
               end
        {
          @spec.test_key => BSON::Binary.from_vector(
            *args,
            validate_vector_data: validate_vector_data
          ),
        }.to_bson.to_s
      end

      def bson
        decode_hex(@canonical_bson)
      end

      private

      def decode_hex(obj)
        [ obj ].pack('H*')
      end
    end
  end
end
