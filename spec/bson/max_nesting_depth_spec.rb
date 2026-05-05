# frozen_string_literal: true
# rubocop:todo all
# Copyright (C) 2026 MongoDB Inc.
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

require "spec_helper"

describe "BSON nesting depth limit" do
  # On JRuby, very deep recursion may overflow the JVM thread stack before
  # our depth counter fires (each Ruby method invocation inflates to multiple
  # JVM frames). Either outcome — BSON::Error::BSONDecodeError or a JVM
  # StackOverflowError — means the process did not crash.
  #
  # The Java throwable is not a subclass of Ruby's Exception, so we rescue it
  # by reference. On MRI it is replaced with an unreachable sentinel.
  java_stack_overflow = if defined?(JRUBY_VERSION)
                         eval('Java::JavaLang::StackOverflowError')
                       else
                         Class.new(Exception)
                       end

  matcher :raise_decode_error_or_stack_overflow do
    supports_block_expectations
    match do |block|
      begin
        block.call
        false
      rescue BSON::Error::BSONDecodeError, SystemStackError, java_stack_overflow
        true
      end
    end
  end


  # Build a BSON byte string with exactly n nested documents:
  # n=1 -> {} (5 bytes), n=2 -> {a: {}}, n=3 -> {a: {a: {}}}, ...
  # Each wrapping level adds 8 bytes of overhead:
  #   int32 length(4) + type(1) + cstring "a\0"(2) + ... + terminator(1)
  # Innermost empty subdoc is 5 bytes.
  def deeply_nested_bson(n)
    wrappers = n - 1
    total = 5 + wrappers * 8
    buf = String.new(capacity: total).force_encoding("BINARY")
    remaining = total
    wrappers.times do
      buf << [remaining].pack("V")
      buf << "\x03".b
      buf << "a\x00".b
      remaining -= 8
    end
    buf << "\x05\x00\x00\x00\x00".b
    wrappers.times { buf << "\x00".b }
    buf
  end

  # Build a BSON byte string with exactly n nested arrays: [], [[]], [[[]]]...
  # Each wrapping level: int32(4) + type 0x04(1) + cstring "0\0"(2) + ... + 0x00(1) = 8.
  def deeply_nested_array_bson(n)
    wrappers = n - 1
    total = 5 + wrappers * 8
    buf = String.new(capacity: total).force_encoding("BINARY")
    remaining = total
    wrappers.times do
      buf << [remaining].pack("V")
      buf << "\x04".b
      buf << "0\x00".b
      remaining -= 8
    end
    buf << "\x05\x00\x00\x00\x00".b
    wrappers.times { buf << "\x00".b }
    buf
  end

  describe "Hash.from_bson" do
    context "when nesting is at the maximum depth" do
      let(:bytes) { deeply_nested_bson(BSON::MAX_NESTING_DEPTH) }

      it "decodes successfully" do
        expect {
          Hash.from_bson(BSON::ByteBuffer.new(bytes))
        }.not_to raise_error
      end
    end

    context "when nesting exceeds the maximum depth" do
      let(:bytes) { deeply_nested_bson(BSON::MAX_NESTING_DEPTH + 1) }

      it "raises BSONDecodeError" do
        expect {
          Hash.from_bson(BSON::ByteBuffer.new(bytes))
        }.to raise_error(BSON::Error::BSONDecodeError, /nesting/i)
      end
    end

    context "when nesting is far beyond the maximum (DoS payload)" do
      let(:bytes) { deeply_nested_bson(100_000) }

      it "raises a decode error or stack overflow without crashing the process" do
        expect {
          Hash.from_bson(BSON::ByteBuffer.new(bytes))
        }.to raise_decode_error_or_stack_overflow
      end
    end
  end

  describe "Array.from_bson via Hash" do
    context "when array nesting exceeds the maximum depth" do
      # Wrap deep arrays inside a single hash so we go through the registered
      # types path: { a: [ [ [ ... ] ] ] }
      let(:bytes) do
        inner = deeply_nested_array_bson(BSON::MAX_NESTING_DEPTH + 1)
        # Wrap: int32 len + 0x04(array) + "a\0" + inner + 0x00
        len = 4 + 1 + 2 + inner.bytesize + 1
        out = String.new(capacity: len).force_encoding("BINARY")
        out << [len].pack("V")
        out << "\x04".b
        out << "a\x00".b
        out << inner
        out << "\x00".b
        out
      end

      it "raises BSONDecodeError" do
        expect {
          Hash.from_bson(BSON::ByteBuffer.new(bytes))
        }.to raise_error(BSON::Error::BSONDecodeError, /nesting/i)
      end
    end
  end

  describe "BSON::ExtJSON.parse_obj" do
    # Build a Ruby structure with exactly n levels of hash nesting:
    # n=1 -> {}, n=2 -> {a: {}}, n=3 -> {a: {a: {}}}, ...
    def deeply_nested_hash(n)
      h = {}
      cur = h
      (n - 1).times { cur["a"] = nxt = {}; cur = nxt }
      h
    end

    # Same for arrays: n=1 -> [], n=2 -> [[]], ...
    def deeply_nested_array(n)
      a = []
      cur = a
      (n - 1).times { cur << (nxt = []); cur = nxt }
      a
    end

    context "when hash nesting is at the maximum depth" do
      let(:input) { deeply_nested_hash(BSON::MAX_NESTING_DEPTH) }

      it "parses successfully" do
        expect { BSON::ExtJSON.parse_obj(input) }.not_to raise_error
      end
    end

    context "when hash nesting exceeds the maximum depth" do
      let(:input) { deeply_nested_hash(BSON::MAX_NESTING_DEPTH + 1) }

      it "raises BSONDecodeError" do
        expect {
          BSON::ExtJSON.parse_obj(input)
        }.to raise_error(BSON::Error::BSONDecodeError, /nesting/i)
      end
    end

    context "when array nesting exceeds the maximum depth" do
      let(:input) { deeply_nested_array(BSON::MAX_NESTING_DEPTH + 1) }

      it "raises BSONDecodeError" do
        expect {
          BSON::ExtJSON.parse_obj(input)
        }.to raise_error(BSON::Error::BSONDecodeError, /nesting/i)
      end
    end

    context "when nesting is far beyond the maximum (DoS payload)" do
      let(:input) { deeply_nested_hash(50_000) }

      it "raises a decode error or stack overflow without crashing the process" do
        expect {
          BSON::ExtJSON.parse_obj(input)
        }.to raise_decode_error_or_stack_overflow
      end
    end
  end
end
