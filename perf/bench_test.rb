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
    @count = 10_000
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
    Array.class_eval <<-EVAL
      def to_bson(encoded = ''.force_encoding(BSON::BINARY))
        encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
          each_with_index do |value, index|
            encoded << value.bson_type
            index.to_s.to_bson_key(encoded)
            value.to_bson(encoded)
          end
        end
      end
    EVAL
  end

  def new_array_index_optimize
    Array.class_eval <<-EVAL
        @@_BSON_INDEX_SIZE = 1024
        @@_BSON_INDEX_ARRAY = ::Array.new(@@_BSON_INDEX_SIZE){|i| (i.to_s.force_encoding(BSON::BINARY) << BSON::NULL_BYTE).freeze}.freeze
        def to_bson(encoded = ''.force_encoding(BSON::BINARY))
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
    EVAL
  end

  def test_array_index_optimization
    size = 1024
    array = Array.new(size){|i| i}
    method_label_pairs = [
      [ method(:old_array_index),          'Array index optimize none' ],
      [ method(:new_array_index_optimize), 'Array index optimize 1024', RESET ] # Xeon user: 20.3, base: 33.2, gain: 0.39
    ]
    benchmark_methods_with_gc(@count, method_label_pairs) { array.to_bson }
  end

  def old_encode_bson_with_placeholder
    BSON::Encodable.module_eval <<-EVAL
      def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BSON::BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE
        encoded[pos, 4] = (encoded.bytesize - pos + adjust).to_bson
        encoded
      end
    EVAL
  end

  def new_encode_bson_with_placeholder_v0
    BSON::Encodable.module_eval <<-EVAL
      def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE
        encoded[pos, 4] = (encoded.bytesize - pos + adjust).to_bson_int32('') # [ encoded.bytesize - pos ].pack('l<') #
        encoded
      end
    EVAL
  end

  def new_encode_bson_with_placeholder_v1
    BSON::Encodable.module_eval <<-EVAL
      def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE
        encoded.set_int32(pos, encoded.bytesize - pos + adjust) # [ encoded.bytesize - pos ].pack('l<') #
        encoded
      end
    EVAL
  end

  def test_encode_bson_with_placeholder
    size = 1
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i.to_s]}.flatten]
    @count = 2_000_000
    method_label_pairs = [
        [ method(:old_encode_bson_with_placeholder),    'Encode bson optimize to_bson' ],
        [ method(:new_encode_bson_with_placeholder_v0), 'Encode bson optimize to_bson_int32' ],  # user: 22.2, base: 28.5, gain: 0.22
        [ method(:new_encode_bson_with_placeholder_v1), 'Encode bson optimize set_int32', RESET ] # user: 22.2, base: 28.5, gain: 0.22
    ]
    benchmark_methods_with_gc(@count, method_label_pairs) { hash.to_bson }
  end

  def old_encode_string_with_placeholder
    BSON::Encodable.module_eval <<-EVAL
      def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BSON::BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE
        encoded[pos, 4] = (encoded.bytesize - pos + adjust).to_bson
        encoded
      end
    EVAL
  end

  def new_encode_string_with_placeholder_v0
    BSON::Encodable.module_eval <<-EVAL
      def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE
        encoded[pos, 4] = (encoded.bytesize - pos + adjust).to_bson_int32('') # [ encoded.bytesize - pos - 4 ].pack('l<') #
        encoded
      end
    EVAL
  end

  def new_encode_string_with_placeholder_v1
    BSON::Encodable.module_eval <<-EVAL
      def encode_with_placeholder_and_null(adjust, encoded = ''.force_encoding(BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE                                           <
        encoded.set_int32(pos, encoded.bytesize - pos + adjust) # [ encoded.bytesize - pos - 4 ].pack('l<') #
        encoded
      end
    EVAL
  end

  def test_encode_string_with_placeholder
    size = 1
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i.to_s]}.flatten]
    @count = 2_000_000
    method_label_pairs = [
        [ method(:old_encode_string_with_placeholder),    'Encode string optimize to_bson' ],
        [ method(:new_encode_string_with_placeholder_v0), 'Encode string optimize to_bson_int32' ],  # Xeon user: 22.2, base: 27.7, gain: 0.20
        [ method(:new_encode_string_with_placeholder_v1), 'Encode string optimize set_int32', RESET ] # Xeon user: 22.2, base: 27.7, gain: 0.20
    ]
    benchmark_methods_with_gc(@count, method_label_pairs) { hash.to_bson }
  end

  def old_integer_to_bson
    Integer.class_eval <<-EVAL
      def to_bson(encoded = ''.force_encoding(BINARY))
        unless bson_int64?
          out_of_range!
        else
          bson_int32? ? to_bson_int32(encoded) : to_bson_int64(encoded)
        end
      end
    EVAL
  end

  def new_integer_to_bson
    Integer.class_eval <<-EVAL
      def to_bson(encoded = ''.force_encoding(BINARY))
        if bson_int32?
          to_bson_int32(encoded)
        elsif bson_int64?
          to_bson_int64(encoded)
        else
          out_of_range!
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
    benchmark_methods_with_gc(@count, method_label_pairs) { hash.to_bson }
  end

  def old_nilclass_to_bson
    BSON::NilClass.class_eval <<-EVAL
      def to_bson(encoded = ''.force_encoding(BSON::BINARY))
        encoded << BSON::NO_VALUE
      end
    EVAL
  end

  def new_nilclass_to_bson
    BSON::NilClass.class_eval <<-EVAL
      def to_bson(encoded = ''.force_encoding(BSON::BINARY))
        encoded
      end
    EVAL
  end

  def test_nilclass_to_bson_optimization
    method_label_pairs = [
      [ method(:old_nilclass_to_bson), 'Nil to_bson optimize none' ],
      [ method(:new_nilclass_to_bson), 'Nil to_bson optimize noop', RESET ] # Core2 user: 4.9, base: 5.7, gain: 0.14
    ]
    benchmark_methods_with_gc(10_000_000, method_label_pairs) { nil.to_bson }
  end

  # C extension in progress -------------------------------------------------------------------------------------------

  def benchmark_for_ext(count, label)
    htms, allocated = gc_allocated do
      tms = Benchmark.measure(label) do
        count.times.each_with_index {|i| yield i }
      end
      Hash[*[:label, :utime, :stime, :cutime, :cstime, :real].zip(tms.to_a).flatten]
    end
    htms.merge!({allocated: allocated, count: count})
  end

  #label: test_ext_rb_float_to_bson, utime: 15.4, real: 16.1, allocated: 3
  #label: test_ext_rb_float_to_bson, utime: 6.1, real: 6.3, allocated: 1
  #gain: 0.61
  def test_ext_rb_float_to_bson
    p (benchmark_for_ext(10000000, __method__) { 3.14159.to_bson })
  end

  #label: "test_ext_rb_time_to_bson", utime: 26.5, real: 26.6, allocated: 6
  #label: "test_ext_rb_time_to_bson", utime: 13.3, real: 13.4, allocated: 4
  #gain: 0.50
  def test_ext_rb_time_to_bson
    t = Time.now
    p (benchmark_for_ext(10000000, __method__) { t.to_bson })
  end

  #label: "test_ext_rb_integer_to_bson_key_large", utime: 18.9, real: 19.1, allocated: 1
  #label: "test_ext_rb_integer_to_bson_key_large", utime: 3.7, real: 3.8, allocated: 0
  #gain: 0.80
  def test_ext_rb_integer_to_bson_key_large
    bson = String.new.force_encoding(BSON::BINARY)
    p (benchmark_for_ext(10000000, __method__) {|i| i.to_bson_key(bson); bson.clear })
  end

  #label: "test_ext_rb_integer_to_bson_key_small", utime: 33.5, real: 34.2, allocated: 0
  #label: "test_ext_rb_integer_to_bson_key_small", utime: 25.4, real: 25.8, allocated: 0
  #gain: 0.24
  def test_ext_rb_integer_to_bson_key_small
    bson = String.new.force_encoding(BSON::BINARY)
    p (benchmark_for_ext(100000000, __method__) {|i| 1023.to_bson_key(bson); bson.clear })
  end

  #label: "test_ext_rb_symbol_to_bson", utime: 36.5, real: 37.0, allocated: 5
  #label: "test_ext_rb_symbol_to_bson", utime: 24.2, real: 24.3, allocated: 3
  #gain: 0.34
  # rb_symbol_to_bson - no C ext, just benefit from other C ext functions
  def test_ext_rb_symbol_to_bson
    bson = String.new.force_encoding(BSON::BINARY)
    p (benchmark_for_ext(10000000, __method__) { :my_symbol.to_bson })
  end

  # Optimization NOT committed ----------------------------------------------------------------------------------------

  def old_hash_to_bson
    Hash.class_eval <<-EVAL
      def to_bson(encoded = ''.force_encoding(BSON::BINARY))
        encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
          each do |field, value|
            encoded << value.bson_type
            field.to_bson_key(encoded)
            value.to_bson(encoded)
          end
        end
      end
    EVAL
  end

  def new_hash_to_bson_v0
    # if-else seems to work better than setting a variable to method
    # pending - mutex
    Hash.class_eval <<-EVAL
      @@_memo_threshold = 65535
      @@_memo_hash = Hash.new
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
      def to_bson(encoded = ''.force_encoding(BSON::BINARY))
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
    EVAL
  end

  def new_hash_to_bson_v1
    Hash.class_eval <<-EVAL
        @@_memo_hash = Hash.new
        def _memo(field)
          @@_memo_hash[field] = @@_memo_hash.fetch(field) { yield }
        end
        def to_bson(encoded = ''.force_encoding(BSON::BINARY))
          encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
            each do |field, value|
              encoded << value.bson_type
              encoded << _memo(field) { field.to_bson_key }
              value.to_bson(encoded)
            end
          end
        end
    EVAL
  end

  def new_hash_to_bson_integer
    Integer.class_eval <<-EVAL
      def bson_type
        BSON::Integer::INT32_TYPE
      end
    EVAL
    Hash.class_eval <<-EVAL
      def to_bson(encoded = ''.force_encoding(BSON::BINARY))
        encode_with_placeholder_and_null(BSON_ADJUST, encoded) do |encoded|
          each do |field, value|
            pos = encoded.bytesize
            encoded << (bson_type = value.bson_type)
            field.to_bson_key(encoded)
            mark = encoded.bytesize
            value.to_bson(encoded)
            encoded[pos] = BSON::Integer::INT64_TYPE if bson_type == BSON::Integer::INT32_TYPE && encoded.bytesize - mark == 8
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
    benchmark_methods_with_gc(@count, method_label_pairs) { hash.to_bson }
  end

  def test_symbol_key_optimization
    size = 1024
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s).to_sym, i]}.flatten]
    method_label_pairs = [
      [ method(:old_hash_to_bson),    'Symbol key optimize none', RESET ],
      [ method(:new_hash_to_bson_v0), 'Symbol key optimize hash key v0' ], # Xeon user: 33.4, base: 35.9, gain: 0.07
      [ method(:new_hash_to_bson_v1), 'Symbol key optimize hash key v1' ]  # Xeon user: 26.4, base: 35.9, gain: 0.26
    ]
    benchmark_methods_with_gc(@count, method_label_pairs) { hash.to_bson }
  end

  def test_string_key_optimization
    size = 1024
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i]}.flatten]
    method_label_pairs = [
        [ method(:old_hash_to_bson),    'Symbol key optimize none', RESET ],
        [ method(:new_hash_to_bson_v0), 'Symbol key optimize hash key v0' ], # Xeon user: 34.5, base: 32.6, gain: -0.06
        [ method(:new_hash_to_bson_v1), 'Symbol key optimize hash key v1' ] # Xeon user: 27.5, base: 32.6, gain: 0.15
    ]
    benchmark_methods_with_gc(@count, method_label_pairs) { hash.to_bson }
  end

  # Discarded as not worthy -------------------------------------------------------------------------------------------

  def old_float_to_bson
    Float.class_eval <<-EVAL
      def to_bson(encoded = ''.force_encoding(BINARY))
        encoded << [ (to_f * 1000.0).to_i ].pack(Int64::PACK)
      end
    EVAL
  end

  def new_float_to_bson
    Float.class_eval <<-EVAL
      def to_bson(encoded = ''.force_encoding(BINARY))
        encoded << [ (sec * 1000 + usec / 1000) ].pack(Int64::PACK)
      end
    EVAL
  end

  def test_float_to_bson_optimization
    t = Time.now
    method_label_pairs = [
      [ method(:old_float_to_bson), 'float to_bson optimize none' ],
      [ method(:new_float_to_bson), 'float to_bson optimize sec usec', RESET ] # Core2 user: 29.5, base: 29.0, gain: -0.02
    ]
    benchmark_methods_with_gc(10_000_000, method_label_pairs) { t.to_bson }
  end

  def old_hash_from_bson
    BSON::Hash.class_eval <<-EVAL
      def from_bson(bson)
        hash = new
        bson.read(4) # Swallow the first four bytes.
        while (type = bson.readbyte.chr) != NULL_BYTE
          field = bson.gets(NULL_BYTE).from_bson_string.chop!
          hash[field] = BSON::Registry.get(type).from_bson(bson)
        end
        hash
      end
    EVAL
  end

  def new_hash_from_bson
    BSON::Hash.class_eval <<-EVAL
      def from_bson(bson)
        hash = new
        bson.seek(4, IO::SEEK_CUR) # Swallow the first four bytes.
        while (type = bson.readbyte.chr) != NULL_BYTE
          field = bson.gets(NULL_BYTE).from_bson_string.chop!
          hash[field] = BSON::Registry.get(type).from_bson(bson)
        end
        hash
      end
    EVAL
  end

  def test_seek
    size = 1
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i.to_s]}.flatten]
    @count = 2_000_000
    method_label_pairs = [
        [ method(:old_hash_from_bson), 'Encode bson optimize none', RESET ],
        [ method(:new_hash_from_bson), 'Encode bson optimize seek' ] # Xeon user: 28.2, base: 28.3, gain: 0.00
    ]
    benchmark_methods_with_gc(@count, method_label_pairs) { hash.to_bson }
  end

  def old_integer_bson_int32?
    Integer.class_eval <<-EVAL
      def bson_int32?
        (MIN_32BIT <= self) && (self <= MAX_32BIT)
      end
    EVAL
  end

  def new_integer_bson_int32?
    Integer.class_eval <<-EVAL
      @@FIXNUM_HIGHBITS32 = (-1 << 32)
      def bson_int32?
        (self & @@FIXNUM_HIGHBITS32) == 0
      end
    EVAL
  end

  def test_bson_int32?
    count = 100_000_000
    method_label_pairs = [
        [ method(:old_integer_bson_int32?),     'Integer#bson_int32? old', RESET ],
        [ method(:new_integer_bson_int32?), 'Integer#bson_int32? new' ] # user: 34.9, base: 21.4, gain: -0.63
    ]
    benchmark_methods_with_gc(count, method_label_pairs) {|i| i.bson_int32? }
  end

  # Statistics and Ruby-prof profiling --------------------------------------------------------------------------------

  # pure Ruby
  #utime: 12.64, allocated: 10, label: "BSON::CodeWithScope"
  #utime: 5.74, allocated:  4, label: "Hash"
  #utime: 5.71, allocated:  4, label: "BSON::Document"
  #utime: 3.87, allocated:  5, label: "Regexp"
  #utime: 3.84, allocated:  4, label: "Array"
  #utime: 3.27, allocated:  4, label: "Symbol"
  #utime: 2.91, allocated: 10, label: "Bignum"
  #utime: 2.84, allocated:  3, label: "String"
  #utime: 2.83, allocated:  3, label: "BSON::Code"
  #utime: 2.13, allocated:  5, label: "Time"
  #utime: 1.97, allocated:  2, label: "BSON::Binary"
  #utime: 1.47, allocated:  0, label: "BSON::Timestamp"
  #utime: 0.91, allocated:  0, label: "Fixnum"
  #utime: 0.91, allocated:  2, label: "Float"
  #utime: 0.37, allocated:  0, label: "BSON::ObjectId"
  #utime: 0.30, allocated:  0, label: "TrueClass"
  #utime: 0.29, allocated:  0, label: "FalseClass"
  #utime: 0.28, allocated:  0, label: "BSON::MaxKey"
  #utime: 0.27, allocated:  0, label: "BSON::Undefined"
  #utime: 0.27, allocated:  0, label: "BSON::MinKey"
  #utime: 0.19, allocated:  0, label: "NilClass"
  # with C extension
  #utime: 6.27, allocated:  4, label: "BSON::CodeWithScope"
  #utime: 3.79, allocated:  5, label: "Regexp"
  #utime: 3.24, allocated:  2, label: "BSON::Document"
  #utime: 3.23, allocated:  2, label: "Hash"
  #utime: 1.95, allocated:  2, label: "Symbol"
  #utime: 1.74, allocated:  2, label: "Array"
  #utime: 1.60, allocated:  1, label: "BSON::Code"
  #utime: 1.55, allocated:  1, label: "String"
  #utime: 1.03, allocated:  3, label: "Time"
  #utime: 0.97, allocated:  0, label: "BSON::Binary"
  #utime: 0.51, allocated:  0, label: "Bignum"
  #utime: 0.38, allocated:  0, label: "BSON::ObjectId"
  #utime: 0.38, allocated:  0, label: "BSON::Timestamp"
  #utime: 0.29, allocated:  0, label: "Fixnum"
  #utime: 0.27, allocated:  0, label: "BSON::Undefined"
  #utime: 0.22, allocated:  0, label: "FalseClass"
  #utime: 0.22, allocated:  0, label: "Float"
  #utime: 0.21, allocated:  0, label: "TrueClass"
  #utime: 0.20, allocated:  0, label: "NilClass"
  #utime: 0.18, allocated:  0, label: "BSON::MinKey"
  #utime: 0.18, allocated:  0, label: "BSON::MaxKey"
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

  def test_encode_ruby_prof
    json_filename = '../../training/data/sampledata/twitter.json'
    line_limit = 10_000
    twitter = nil
    File.open(json_filename, 'r') do |f|
      twitter = line_limit.times.collect { JSON.parse(f.gets) }
    end


    profile = nil
    allocated = nil
    Benchmark.bm(@label_width) do |bench|
      bench.report('test encode ruby prof') do

        result, allocated = gc_allocated do
          RubyProf.start
          twitter.each {|doc| doc.to_bson }
          profile = RubyProf.stop
        end

      end
    end
    puts "allocated: #{allocated} allocated/line: #{allocated/line_limit}"

    File.open('encode-ruby-prof.out', 'w') do |f|
      RubyProf::FlatPrinter.new(profile).print(f)
      RubyProf::GraphPrinter.new(profile).print(f, {})
    end
  end

  def test_decode_ruby_prof
    json_filename = '../../training/data/sampledata/twitter.json'
    line_limit = 10_000
    twitter = nil
    File.open(json_filename, 'r') do |f|
      twitter = line_limit.times.collect { StringIO.new(JSON.parse(f.gets).to_bson) }
    end

    profile = nil
    allocated = nil
    Benchmark.bm(@label_width) do |bench|
      bench.report('test decode ruby prof') do

        result, allocated = gc_allocated do
          RubyProf.start
          twitter.each {|io| io.rewind; Hash.from_bson(io) }
          profile = RubyProf.stop
        end

      end
    end
    puts "allocated: #{allocated} allocated/line: #{allocated/line_limit}"

    File.open('decode-ruby-prof.out', 'w') do |f|
      RubyProf::FlatPrinter.new(profile).print(f)
      RubyProf::GraphPrinter.new(profile).print(f, {})
    end
  end

end

