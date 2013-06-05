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

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'bson'
require 'json'
require 'stringio'
require 'test/unit'
require 'benchmark'
require 'ruby-prof' unless RUBY_PLATFORM =~ /java/

class BenchTest < Test::Unit::TestCase
  RESET = 'reset'
  NON_ZERO_TIME = 0.0000000001 # 10^-10

  def setup
    puts
    @label_width = 30
  end

  def teardown
    puts
  end

  def gc_allocated
    gc_stat = []
    GC.start
    gc_stat << GC.stat
    result = yield
    GC.start
    gc_stat << GC.stat
    [ result, gc_stat[1][:total_allocated_object] - gc_stat[0][:total_allocated_object] ]
  end

  def print_measurement_and_gain(measurement, j)
    h = measurement[j]
    h[:allocated] /= h[:count]
    if j > 0
      h[:base] = measurement[0][:utime]
      h[:gain] = 1.0 - h[:utime] / (h[:base] + NON_ZERO_TIME)
    end
    [
        [ "label: \"%s\"", :label ],
        [ ", allocated: %d", :allocated ],
        [ ", user: %.1f", :utime ],
        [ ", base: %.1f", :base ],
        [ ", gain: %.2f", :gain ]
    ].each do |format, key|
      print (format % h[key]) if h[key]
    end
    puts
  end

  def benchmark_methods_with_gc(count, method_label_pairs)
    measurement = []
    method_label_pairs.each_with_index do |method_label_pair, j|
      meth, label = method_label_pair
      meth.call
      htms, allocated = gc_allocated do
        tms = Benchmark.measure(label) do
          count.times.each_with_index {|i| yield i }
        end
        Hash[*[:label, :utime, :stime, :cutime, :cstime, :real].zip(tms.to_a).flatten]
      end
      htms.merge!({allocated: allocated, count: count})
      measurement << htms
      print_measurement_and_gain(measurement, j)
    end
    reset_method = method_label_pairs.find(method_label_pairs.first){|ml| ml[2] && ml[2] == RESET}.first
    reset_method.call
  end

  # Optimization committed --------------------------------------------------------------------------------------------

  def old_array_index
    BSON.module_eval <<-EVAL
      module Array
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
            each_with_index do |value, index|
              encoded << value.bson_type
              index.to_s.to_bson_key(encoded)
              value.to_bson(encoded)
            end
          end
        end
      end
    EVAL
  end

  def new_array_index_optimize
    BSON.module_eval <<-EVAL
      module Array
        @@_BSON_INDEX_SIZE = 1024
        @@_BSON_INDEX_ARRAY = ::Array.new(@@_BSON_INDEX_SIZE){|i| (i.to_s.force_encoding(BINARY) << NULL_BYTE).freeze}.freeze
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
            each_with_index do |value, index|
              encoded << value.bson_type
              if index < @@_BSON_INDEX_SIZE
                encoded << @@_BSON_INDEX_ARRAY[index]
              else
                index.to_s.to_bson_cstring(encoded)
              end
              value.to_bson(encoded)
            end
          end
        end
      end
    EVAL
  end

  def test_array_index_optimization
    size = 1024
    array = Array.new(size){|i| i}
    method_label_pairs = [
      [ method(:old_array_index),          'Array index optimize none' ],
      [ method(:new_array_index_optimize), 'Array index optimize 1024', RESET ] # Xeon user: 20.3, base: 33.2, gain: 0.39
    ]
    benchmark_methods_with_gc(1_000, method_label_pairs) { array.to_bson }
  end

  def old_encode_bson_with_placeholder
    BSON.module_eval <<-EVAL
      module Encodable
        def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BINARY))
          pos = encoded.bytesize
          encoded << PLACEHOLDER
          yield(encoded)
          encoded << NULL_BYTE
          encoded[pos, 4] = (encoded.bytesize - pos + adjust).to_bson
          encoded
        end
      end
    EVAL
  end

  def new_encode_bson_with_placeholder_to_bson_int32
    BSON.module_eval <<-EVAL
      module Encodable
        def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BINARY))
          pos = encoded.bytesize
          encoded << PLACEHOLDER
          yield(encoded)
          encoded << NULL_BYTE
          encoded[pos, 4] = (encoded.bytesize - pos + adjust).to_bson_int32('')
          encoded
        end
      end
    EVAL
  end

  def new_encode_bson_with_placeholder_set_int32
    BSON.module_eval <<-EVAL
      module Encodable
        def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BINARY))
          pos = encoded.bytesize
          encoded << PLACEHOLDER
          yield(encoded)
          encoded << NULL_BYTE
          encoded.set_int32(pos, encoded.bytesize - pos + adjust)
          encoded
        end
      end
    EVAL
  end

  def test_encode_bson_with_placeholder
    size = 1
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i.to_s]}.flatten]
    method_label_pairs = [
        [ method(:old_encode_bson_with_placeholder),              'Encode bson optimize to_bson' ],
        [ method(:new_encode_bson_with_placeholder_to_bson_int32), 'Encode bson optimize to_bson_int32' ],  # user: 22.2, base: 28.5, gain: 0.22
        [ method(:new_encode_bson_with_placeholder_set_int32),    'Encode bson optimize set_int32', RESET ] # user: 22.2, base: 28.5, gain: 0.22
    ]
    benchmark_methods_with_gc(1_000_000, method_label_pairs) { hash.to_bson }
  end

  def old_integer_to_bson
    BSON.module_eval <<-EVAL
      module Integer
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          unless bson_int64?
            out_of_range!
          else
            bson_int32? ? to_bson_int32(encoded) : to_bson_int64(encoded)
          end
        end
      end
    EVAL
  end

  def new_integer_to_bson
    BSON.module_eval <<-EVAL
      module Integer
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          if bson_int32?
            to_bson_int32(encoded)
          elsif bson_int64?
            to_bson_int64(encoded)
          else
            out_of_range!
          end
        end
      end
    EVAL
  end

  def test_integer_to_bson_optimization
    size = 1024
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s).to_sym, i]}.flatten]
    method_label_pairs = [
      [ method(:old_integer_to_bson), 'Integer to_bson optimize none' ],
      [ method(:new_integer_to_bson), 'Integer to_bson optimize test order', RESET ]
    ]
    benchmark_methods_with_gc(2_000, method_label_pairs) { hash.to_bson }
  end

  def old_nilclass_to_bson
    BSON.module_eval <<-EVAL
      module NilClass
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          encoded << NO_VALUE
        end
      end
    EVAL
  end

  def new_nilclass_to_bson
    BSON.module_eval <<-EVAL
      module NilClass
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          encoded
        end
      end
    EVAL
  end

  def test_nilclass_to_bson_optimization
    method_label_pairs = [
      [ method(:old_nilclass_to_bson), 'Nil to_bson optimize none' ],
      [ method(:new_nilclass_to_bson), 'Nil to_bson optimize noop', RESET ] # Core2 user: 4.9, base: 5.7, gain: 0.14
    ]
    benchmark_methods_with_gc(20_000_000, method_label_pairs) { nil.to_bson }
  end

  # C extension -------------------------------------------------------------------------------------------------------

  def benchmark_for_ext(count, label)
    htms, allocated = gc_allocated do
      tms = Benchmark.measure(label) do
        count.times.each_with_index {|i| yield i }
      end
      Hash[*[:label, :utime, :stime, :cutime, :cstime, :real].zip(tms.to_a).flatten]
    end
    htms.merge!({allocated: allocated, count: count})
  end

  #label: "test_ext_rb_string_check_for_illegal_characters!", utime: 19.3, real: 19.7, allocated: 3
  #label: "test_ext_rb_string_check_for_illegal_characters!", utime: 16.3, real: 16.6, allocated: 4
  #gain: 0.15
  def test_ext_rb_string_check_for_illegal_characters!
    p (benchmark_for_ext(10_000_000, __method__) { "Hello World!".to_bson_cstring })
  end

  #label: test_ext_rb_float_to_bson, utime: 15.4, real: 16.1, allocated: 3
  #label: test_ext_rb_float_to_bson, utime: 6.1, real: 6.3, allocated: 1
  #gain: 0.61
  def test_ext_rb_float_to_bson
    p (benchmark_for_ext(10_000_000, __method__) { 3.14159.to_bson })
  end

  #label: "test_ext_rb_time_to_bson", utime: 26.5, real: 26.6, allocated: 6
  #label: "test_ext_rb_time_to_bson", utime: 13.3, real: 13.4, allocated: 4
  #gain: 0.50
  def test_ext_rb_time_to_bson
    t = Time.now
    p (benchmark_for_ext(10_000_000, __method__) { t.to_bson })
  end

  #label: "test_ext_rb_integer_to_bson_key_large", utime: 18.9, real: 19.1, allocated: 1
  #label: "test_ext_rb_integer_to_bson_key_large", utime: 3.7, real: 3.8, allocated: 0
  #gain: 0.80
  def test_ext_rb_integer_to_bson_key_large
    bson = String.new.force_encoding(BSON::BINARY)
    p (benchmark_for_ext(10_000_000, __method__) {|i| i.to_bson_key(bson); bson.clear })
  end

  #label: "test_ext_rb_integer_to_bson_key_small", utime: 33.5, real: 34.2, allocated: 0
  #label: "test_ext_rb_integer_to_bson_key_small", utime: 25.4, real: 25.8, allocated: 0
  #gain: 0.24
  def test_ext_rb_integer_to_bson_key_small
    bson = String.new.force_encoding(BSON::BINARY)
    p (benchmark_for_ext(10_0000_000, __method__) {|i| 1023.to_bson_key(bson); bson.clear })
  end

  #label: "test_ext_rb_symbol_to_bson", utime: 36.5, real: 37.0, allocated: 5
  #label: "test_ext_rb_symbol_to_bson", utime: 24.2, real: 24.3, allocated: 3
  #gain: 0.34
  # rb_symbol_to_bson - no C ext, just benefit from other C ext functions
  def test_ext_rb_symbol_to_bson
    bson = String.new.force_encoding(BSON::BINARY)
    p (benchmark_for_ext(10_000_000, __method__) { :my_symbol.to_bson })
  end

  # Optimization NOT committed ----------------------------------------------------------------------------------------

  # MongoDB driver overrides ------------------------------------------------------------------------------------------

  def old_string_to_bson_key
    BSON.module_eval <<-EVAL
      module String
        def to_bson_key(encoded = ''.force_encoding(BINARY))
          to_bson_cstring(encoded)
        end
      end
    EVAL
  end

  def new_string_to_bson_key_flag
    BSON.module_eval <<-EVAL
      module String
        def to_bson_key(encoded = ''.force_encoding(BINARY))
          nil if encoded.instance_variable_get(:@bson_key_check_skip)
          to_bson_cstring(encoded)
        end
      end
    EVAL
  end

  def new_string_to_bson_key_mongodb
    BSON.module_eval <<-EVAL
      module String
        def to_bson_key(encoded = ''.force_encoding(BINARY))
          check_for_illegal_mongodb_key_characters!(encoded)
          to_bson_cstring(encoded)
        end

        def check_for_illegal_mongodb_key_characters!(encoded)
          unless encoded.instance_variable_get(:@bson_key_check_skip)
            raise "key \#{self.inspect} must not start with '$'" if self[0] == ?$
            raise "key \#{self.inspect} must not contain '.'"   if self.include? ?.
          end
        end
      end
    EVAL
  end

  #label: "string to_bson_key", allocated: 2, user: 18.3
  #label: "string to_bson_key flag check", allocated: 2, user: 19.6, base: 18.3, gain: -0.07
  #label: "string to_bson_key mongodb", allocated: 2, user: 20.6, base: 18.3, gain: -0.12
  def test_string_to_bson_key_mongodb
    encoded = ''
    encoded.instance_variable_set(:@bson_key_check_skip, true)
    method_label_pairs = [
      [ method(:old_string_to_bson_key),         'string to_bson_key', RESET ],
      [ method(:new_string_to_bson_key_flag),    'string to_bson_key flag check' ],
      [ method(:new_string_to_bson_key_mongodb), 'string to_bson_key mongodb' ] # Core2 user: 29.5, base: 29.0, gain: -0.02
    ]
    benchmark_methods_with_gc(10_000_000, method_label_pairs) { 'email_address'.to_bson_key(encoded); encoded.clear }
  end

  # Discarded as not worthy -------------------------------------------------------------------------------------------

  #                                     user     system      total        real
  #test_encode_twitter            289.520000   0.900000 290.420000 (294.547515) to_bson no hint pure
  #allocated: 11563746 allocated/line: 224
  #test_encode_twitter            293.320000   0.910000 294.230000 (298.737329) to_bson hint pure
  #allocated: 11423424 allocated/line: 222

  def old_hash_to_bson_no_hint
    BSON.module_eval <<-EVAL
      module Hash
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
            each do |field, value|
              encoded << value.bson_type
              field.to_bson_key(encoded)
              value.to_bson(encoded)
            end
          end
        end
      end
    EVAL
  end

  def new_hash_to_bson_hint
    BSON.module_eval <<-EVAL
      module Hash
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
            each do |field, value|
              encoded << (bson_type = value.bson_type)
              field.to_bson_key(encoded)
              value.to_bson(encoded, bson_type)
            end
          end
        end
      end
      module Integer
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          if hint == Int32::BSON_TYPE
            to_bson_int32(encoded)
          elsif hint == Int64::BSON_TYPE
            to_bson_int64(encoded)
          elsif bson_int32?
            to_bson_int32(encoded)
          elsif bson_int64?
            to_bson_int64(encoded)
          else
            out_of_range!
          end
        end
      end
      module String
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          encode_with_placeholder_and_null(STRING_ADJUST, encoded) do |encoded|
            to_bson_string(encoded)
          end
        end
      end
    EVAL
  end

  def test_hash_integer_to_bson_hint
    size = 1024
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i]}.flatten]
    method_label_pairs = [
        [ method(:old_hash_to_bson_no_hint), 'Hash integer to_bson no hint' ],
        [ method(:new_hash_to_bson_hint),    'Hash integer to_bson hint', RESET ], # Core2 user: 25.1, base: 33.8, gain: 0.26
    ]
    benchmark_methods_with_gc(4_000, method_label_pairs) { hash.to_bson }
  end

  def test_hash_string_to_bson_hint # to check overhead of hint setting and passing
    size = 1024
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i.to_s]}.flatten]
    method_label_pairs = [
        [ method(:old_hash_to_bson_no_hint), 'Hash string to_bson no hint', RESET ],
        [ method(:new_hash_to_bson_hint),    'Hash string to_bson hint' ], # Core2 user: 19.8, base: 19.7, gain: -0.00
    ]
    benchmark_methods_with_gc(4_000, method_label_pairs) { hash.to_bson }
  end

  def old_hash_to_bson
    BSON.module_eval <<-EVAL
      module Hash
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
            each do |field, value|
              encoded << value.bson_type
              field.to_bson_key(encoded)
              value.to_bson(encoded)
            end
          end
        end
      end
    EVAL
  end

  def new_hash_to_bson_v0
    # if-else seems to work better than setting a variable to method
    # pending - mutex
    BSON.module_eval <<-EVAL
      module Hash
        @@_memo_threshold = 65535
        @@_memo_hash = ::Hash.new
        @@_memo_mutex = Mutex.new
        def _memo_set(field)
          @@_memo_mutex.synchronize do
            @@_memo_hash[field] = @@_memo_hash.fetch(field) { yield }
          end
        end
        def _memo_fetch(field)
          @@_memo_mutex.synchronize do
            @@_memo_hash.fetch(field) { yield }
          end
        end
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          if size < @@_memo_threshold
            encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
              each do |field, value|
                encoded << value.bson_type
                encoded << _memo_set(field) { field.to_bson_key }
                value.to_bson(encoded)
              end
            end
          else
            encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
              each do |field, value|
                encoded << value.bson_type
                encoded << _memo_fetch(field) { field.to_bson_key }
                value.to_bson(encoded)
              end
            end
          end
        end
      end
    EVAL
  end

  def new_hash_to_bson_v1
    BSON.module_eval <<-EVAL
      module Hash
        @@_memo_hash = ::Hash.new
        def _memo(field)
          @@_memo_hash[field] = @@_memo_hash.fetch(field) { yield }
        end
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
            each do |field, value|
              encoded << value.bson_type
              encoded << _memo(field) { field.to_bson_key }
              value.to_bson(encoded)
            end
          end
        end
      end
    EVAL
  end

  def new_hash_to_bson_integer
    BSON.module_eval <<-EVAL
      module Integer
        def bson_type
          Integer::INT32_TYPE
        end
      end
      module Hash
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
            each do |field, value|
              pos = encoded.bytesize
              encoded << (bson_type = value.bson_type)
              field.to_bson_key(encoded)
              mark = encoded.bytesize
              value.to_bson(encoded)
              encoded[pos] = Integer::INT64_TYPE if bson_type == Integer::INT32_TYPE && encoded.bytesize - mark == 8
            end
          end
        end
      end
    EVAL
  end

  # without extension 0.23 gain, with extension -0.11 gain
  def test_integer_optimization
    size = 1024
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s).to_sym, i]}.flatten]
    method_label_pairs = [
      [ method(:old_hash_to_bson),         'Integer optimize none', RESET ],
      [ method(:new_hash_to_bson_integer), 'Integer optimize int32' ], # Core2 user: 68.2, base: 88.1, gain: 0.23
    ]
    benchmark_methods_with_gc(4_000, method_label_pairs) { hash.to_bson }
  end

  def test_symbol_key_optimization
    size = 1024
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s).to_sym, i]}.flatten]
    method_label_pairs = [
      [ method(:old_hash_to_bson),    'Symbol key optimize none', RESET ],
      [ method(:new_hash_to_bson_v0), 'Symbol key optimize hash key v0' ], # Xeon user: 33.4, base: 35.9, gain: 0.07
      [ method(:new_hash_to_bson_v1), 'Symbol key optimize hash key v1' ]  # Xeon user: 26.4, base: 35.9, gain: 0.26
    ]
    benchmark_methods_with_gc(2_000, method_label_pairs) { hash.to_bson }
  end

  def test_string_key_optimization
    size = 1024
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i]}.flatten]
    method_label_pairs = [
        [ method(:old_hash_to_bson),    'Symbol key optimize none', RESET ],
        [ method(:new_hash_to_bson_v0), 'Symbol key optimize hash key v0' ], # Xeon user: 34.5, base: 32.6, gain: -0.06
        [ method(:new_hash_to_bson_v1), 'Symbol key optimize hash key v1' ] # Xeon user: 27.5, base: 32.6, gain: 0.15
    ]
    benchmark_methods_with_gc(2_000, method_label_pairs) { hash.to_bson }
  end

  def old_time_to_bson
    BSON.module_eval <<-EVAL
      module Time
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          encoded << [ (to_f * 1000.0).to_i ].pack(Int64::PACK)
        end
      end
    EVAL
  end

  def new_time_to_bson
    BSON.module_eval <<-EVAL
      module Time
        def to_bson(encoded = ''.force_encoding(BINARY), hint = nil)
          encoded << [ (sec * 1000 + usec / 1000) ].pack(Int64::PACK)
        end
      end
    EVAL
  end

  def test_time_to_bson_optimization
    t = Time.now
    method_label_pairs = [
      [ method(:old_time_to_bson), 'time to_bson optimize none' ],
      [ method(:new_time_to_bson), 'time to_bson optimize sec usec', RESET ] # Core2 user: 29.5, base: 29.0, gain: -0.02
    ]
    benchmark_methods_with_gc(10_000_000, method_label_pairs) { t.to_bson }
  end

  def old_hash_from_bson
    BSON.module_eval <<-EVAL
      module Hash
        def from_bson(bson)
          hash = new
          bson.read(4) # Swallow the first four bytes.
          while (type = bson.readbyte.chr) != NULL_BYTE
            field = bson.gets(NULL_BYTE).from_bson_string.chop!
            hash[field] = Registry.get(type).from_bson(bson)
          end
          hash
        end
      end
    EVAL
  end

  def new_hash_from_bson
    BSON.module_eval <<-EVAL
      module Hash
        def from_bson(bson)
        hash = new
          bson.seek(4, IO::SEEK_CUR) # Swallow the first four bytes.
          while (type = bson.readbyte.chr) != NULL_BYTE
            field = bson.gets(NULL_BYTE).from_bson_string.chop!
            hash[field] = Registry.get(type).from_bson(bson)
          end
          hash
        end
      end
    EVAL
  end

  #review with just op, without hash overhead, check allocation
  def test_seek
    size = 1
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i.to_s]}.flatten]
    method_label_pairs = [
        [ method(:old_hash_from_bson), 'Encode bson optimize none', RESET ],
        [ method(:new_hash_from_bson), 'Encode bson optimize seek' ] # Xeon user: 28.2, base: 28.3, gain: 0.00
    ]
    benchmark_methods_with_gc(2_000_000, method_label_pairs) { hash.to_bson }
  end

  def old_integer_bson_int32?
    BSON.module_eval <<-EVAL
      module Integer
        def bson_int32?
          (MIN_32BIT <= self) && (self <= MAX_32BIT)
        end
      end
    EVAL
  end

  def new_integer_bson_int32?
    BSON.module_eval <<-EVAL
      module Integer
        @@FIXNUM_HIGHBITS32 = (-1 << 32)
        def bson_int32?
          (self & @@FIXNUM_HIGHBITS32) == 0
        end
      end
    EVAL
  end

  def test_bson_int32?
    method_label_pairs = [
        [ method(:old_integer_bson_int32?),     'Integer#bson_int32? old', RESET ],
        [ method(:new_integer_bson_int32?), 'Integer#bson_int32? new' ] # user: 34.9, base: 21.4, gain: -0.63
    ]
    benchmark_methods_with_gc(100_000_000, method_label_pairs) {|i| i.bson_int32? }
  end

  # Statistics and Ruby-prof profiling --------------------------------------------------------------------------------

  # pure Ruby - Core2
  #utime: 13.92, allocated: 10, label: "BSON::CodeWithScope"
  #utime: 6.12, allocated:  4, label: "Hash"
  #utime: 6.11, allocated:  4, label: "BSON::Document"
  #utime: 4.61, allocated:  5, label: "Regexp"
  #utime: 4.09, allocated:  4, label: "Array"
  #utime: 3.70, allocated:  4, label: "Symbol"
  #utime: 3.50, allocated: 10, label: "Bignum"
  #utime: 3.27, allocated:  3, label: "BSON::Code"
  #utime: 3.21, allocated:  3, label: "String"
  #utime: 2.54, allocated:  5, label: "Time"
  #utime: 2.08, allocated:  2, label: "BSON::Binary"
  #utime: 1.57, allocated:  0, label: "BSON::Timestamp"
  #utime: 1.04, allocated:  2, label: "Float"
  #utime: 0.93, allocated:  0, label: "Fixnum"
  #utime: 0.42, allocated:  0, label: "BSON::ObjectId"
  #utime: 0.29, allocated:  0, label: "TrueClass"
  #utime: 0.29, allocated:  0, label: "FalseClass"
  #utime: 0.19, allocated:  0, label: "BSON::MinKey"
  #utime: 0.19, allocated:  0, label: "BSON::MaxKey"
  #utime: 0.19, allocated:  0, label: "NilClass"
  #utime: 0.19, allocated:  0, label: "BSON::Undefined"
  # with C extension - Core2
  #utime: 6.12, allocated:  6, label: "BSON::CodeWithScope"
  #utime: 3.70, allocated:  7, label: "Regexp"
  #utime: 3.17, allocated:  3, label: "Hash"
  #utime: 3.16, allocated:  3, label: "BSON::Document"
  #utime: 1.89, allocated:  3, label: "Symbol"
  #utime: 1.89, allocated:  2, label: "Array"
  #utime: 1.53, allocated:  2, label: "BSON::Code"
  #utime: 1.47, allocated:  2, label: "String"
  #utime: 1.30, allocated:  3, label: "Time"
  #utime: 0.97, allocated:  0, label: "BSON::Binary"
  #utime: 0.57, allocated:  0, label: "Bignum"
  #utime: 0.38, allocated:  0, label: "BSON::ObjectId"
  #utime: 0.38, allocated:  0, label: "BSON::Timestamp"
  #utime: 0.29, allocated:  0, label: "Fixnum"
  #utime: 0.22, allocated:  0, label: "Float"
  #utime: 0.21, allocated:  0, label: "FalseClass"
  #utime: 0.20, allocated:  0, label: "TrueClass"
  #utime: 0.20, allocated:  0, label: "BSON::MaxKey"
  #utime: 0.20, allocated:  0, label: "BSON::MinKey"
  #utime: 0.20, allocated:  0, label: "BSON::Undefined"
  #utime: 0.19, allocated:  0, label: "NilClass"
  def test_to_bson_object_allocation
    count = 1_000_000
    t = Time.now
    expression = [
      Array[1],
      BSON::Binary.new("xyzzy"),
      BSON::Code.new("new Object;"),
      BSON::CodeWithScope.new("new Object;", {x: 1}),
      BSON::Document['x', 1],
      false,
      3.14159,
      Hash['x', 1],
      2**31 - 1,
      2**63 - 1,
      BSON::MaxKey.new,
      BSON::MinKey.new,
      nil,
      BSON::ObjectId.new,
      /xyzzy/,
      'xyzzy',
      :xyzzy,
      Time.now,
      BSON::Timestamp.new(t.sec, t.usec),
      true,
      BSON::Undefined.new
    ]
    result = expression.collect do |x|
      htms, allocated = gc_allocated do
        tms = Benchmark.measure(x.class.name) do
          encoded = ''.force_encoding(BSON::BINARY)
          count.times { x.to_bson(encoded); encoded.clear }
        end
        Hash[*[:label, :utime, :stime, :cutime, :cstime, :real].zip(tms.to_a).flatten]
      end
      htms.merge!({allocated: allocated, count: count})
    end
    result.sort!{|a,b| b[:utime] <=> a[:utime]}
    result.each do |h|
      puts "utime: #{'%.2f' % h[:utime]}, allocated: #{'%2d' % (h[:allocated]/h[:count])}, label: #{h[:label].inspect}"
    end
  end

  def doc_stats(tally, obj)
    tally[obj.class.name] += 1
    case obj.class.name
      when 'Array'; obj.each {|elem| doc_stats(tally, elem) }
      when 'FalseClass'; return
      when 'Fixnum'; return
      when 'Float'; return
      when 'Hash'; obj.each {|elem| doc_stats(tally, elem) }
      when 'NilClass'; return
      when 'String'; return
      when 'TrueClass'; return
      else p obj.class; exit
    end
  end

  #0.44 String 811731
  #0.35 Array 646586
  #0.07 NilClass 120515
  #0.06 Fixnum 120181
  #0.05 FalseClass 89655
  #0.02 Hash 44144
  #0.01 TrueClass 18245
  #0.00 Float 996
  #objects: 1852053
  #objects/doc: 185
  def test_doc_stats
    json_filename = '../../training/data/sampledata/twitter.json'
    line_limit = 10_000
    twitter = nil
    File.open(json_filename, 'r') do |f|
      twitter = line_limit.times.collect { JSON.parse(f.gets) }
    end
    tally = Hash.new(0)
    doc_stats(tally, twitter)
    obj_count = tally.inject(0){|sum, elem| sum + elem[1]}
    tally = tally.to_a.sort{|a,b| b[1] <=> a[1]}
    tally.each {|a| puts "#{'%.2f' % (a[1].to_f / obj_count.to_f)} #{a[0]} #{a[1]}" }
    puts "objects: #{obj_count}"
    puts "objects/doc: #{obj_count/line_limit}"
  end

  def get_twitter_data(line_limit, bson)
    json_filename = '../../training/data/sampledata/twitter.json'
    File.open(json_filename, 'r') do |f|
      f.readlines[0..line_limit].collect {|line| doc = JSON.parse(line); bson ? StringIO.new(doc.to_bson) : doc }
    end
  end

  def test_encode_twitter
    twitter = get_twitter_data(-1, false)
    allocated = nil
    Benchmark.bm(@label_width) do |bench|
      bench.report(__method__) do
        result, allocated = gc_allocated do
          twitter.each {|doc| doc.to_bson }
        end
      end
    end
    puts "allocated: #{allocated} allocated/line: #{allocated/twitter.size}"
  end

  def test_decode_twitter
    twitter = get_twitter_data(-1, false)
    allocated = nil
    Benchmark.bm(@label_width) do |bench|
      bench.report(__method__) do
        result, allocated = gc_allocated do
          twitter = get_twitter_data(-1, true)
        end
      end
    end
    puts "allocated: #{allocated} allocated/line: #{allocated/twitter.size}"
  end

  def ruby_prof(label, bson, file_name)
    allocated = nil
    line_limit = nil
    profile = nil
    Benchmark.bm(@label_width) do |bench|
      bench.report(label) do
        result, allocated = gc_allocated do
          RubyProf.start
          line_limit = yield
          profile = RubyProf.stop
        end
      end
    end
    puts "allocated: #{allocated} allocated/line: #{allocated/line_limit}"
    File.open(file_name, 'w') do |f|
      RubyProf::FlatPrinter.new(profile).print(f)
      RubyProf::GraphPrinter.new(profile).print(f, {})
    end
  end

  def test_encode_ruby_prof
    twitter = get_twitter_data(10_000, false)
    ruby_prof('test encode ruby prof', false, 'encode-ruby-prof.out') do
      twitter.each {|doc| doc.to_bson }
      twitter.size
    end
  end

  def test_decode_ruby_prof
    twitter = get_twitter_data(10_000, true)
    ruby_prof('test decode ruby prof', true, 'decode-ruby-prof.out') do
      twitter.each {|io| io.rewind; Hash.from_bson(io) }
      twitter.size
    end
  end

end
