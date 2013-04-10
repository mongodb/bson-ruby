$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'bson'
require 'json'
require 'test/unit'
require 'benchmark'
require 'ruby-prof'

class BenchTest < Test::Unit::TestCase

  def setup
    puts
    @count = 10_000
    @label_width = 30
  end

  def teardown
    puts
  end

  def print_gain(modification_tms, base_tms)
    puts "gain: #{'%.2f' % (1.0 - modification_tms.utime/base_tms.utime)} (#{base_tms.utime.round} --> #{modification_tms.utime.round})"
  end

  def reset_old_array_index
    Array.class_eval <<-EVAL
      def to_bson(encoded = ''.force_encoding(BSON::BINARY))
        encode_bson_with_placeholder(encoded) do |encoded|
          each_with_index do |value, index|
            encoded << value.bson_type
            index.to_s.to_bson_cstring(encoded)
            value.to_bson(encoded)
          end
        end
      end
    EVAL
  end

  def set_new_array_index_optimize
    Array.class_eval <<-EVAL
        @@_BSON_INDEX_SIZE = 1024
        @@_BSON_INDEX_ARRAY = ::Array.new(@@_BSON_INDEX_SIZE){|i| (i.to_s.force_encoding(BSON::BINARY) << BSON::NULL_BYTE).freeze}.freeze
        def to_bson(encoded = ''.force_encoding(BSON::BINARY))
          encode_bson_with_placeholder(encoded) do |encoded|
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

    measurement = []
    Benchmark.bm(@label_width) do |bench|

      reset_old_array_index
      measurement << bench.report('Array index optimize none') do
        @count.times { array.to_bson }
      end

      set_new_array_index_optimize
      measurement << bench.report('Array index optimize 1024') do
        @count.times { array.to_bson }
      end

      set_new_array_index_optimize # committed
    end
    print_gain(measurement[1], measurement[0])
  end

  def reset_old_encode_string_with_placeholder
    BSON::Encodable.module_eval <<-EVAL
      def encode_string_with_placeholder(encoded = ''.force_encoding(BSON::BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE
        encoded[pos, 4] = (encoded.bytesize - pos - 4).to_bson
        encoded
      end
    EVAL
  end

  def set_new_encode_sring_with_placeholder
    BSON::Encodable.module_eval <<-EVAL
      def encode_string_with_placeholder(encoded = ''.force_encoding(BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE
        encoded[pos, 4] = (encoded.bytesize - pos - 4).send(:to_bson_int32) # [ encoded.bytesize - pos - 4 ].pack('l<') #
        encoded
      end
    EVAL
  end

  def test_encode_string_with_placeholder
    size = 1
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i.to_s]}.flatten]
    @count = 2_000_000
    measurement = []
    Benchmark.bm(@label_width) do |bench|

      reset_old_encode_string_with_placeholder
      measurement << bench.report('Encode string optimize none') do
        @count.times { hash.to_bson }
      end

      set_new_encode_sring_with_placeholder
      measurement << bench.report('Encode string optimize pack0') do
        @count.times { hash.to_bson }
      end

      reset_old_encode_string_with_placeholder
    end
    print_gain(measurement[1], measurement[0])
  end

  def reset_old_encode_bson_with_placeholder
    BSON::Encodable.module_eval <<-EVAL
      def encode_bson_with_placeholder(encoded = ''.force_encoding(BSON::BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE
        encoded[pos, 4] = (encoded.bytesize - pos).to_bson
        encoded
      end
     EVAL
  end

  def set_new_encode_bson_with_placeholder
    BSON::Encodable.module_eval <<-EVAL
      def encode_bson_with_placeholder(encoded = ''.force_encoding(BINARY))
        pos = encoded.bytesize
        encoded << PLACEHOLDER
        yield(encoded)
        encoded << BSON::NULL_BYTE
        encoded[pos, 4] = (encoded.bytesize - pos).send(:to_bson_int32) # [ encoded.bytesize - pos ].pack('l<') #
        encoded
      end
     EVAL
  end

  def test_encode_bson_with_placeholder
    size = 1
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i.to_s]}.flatten]
    @count = 2_000_000
    measurement = []
    Benchmark.bm(@label_width) do |bench|

      reset_old_encode_bson_with_placeholder
      measurement << bench.report('Encode bson optimize none') do
        @count.times { hash.to_bson }
      end

      set_new_encode_bson_with_placeholder
      measurement << bench.report('Encode bson optimize pack') do
        @count.times { hash.to_bson }
      end

      reset_old_encode_bson_with_placeholder
    end
    print_gain(measurement[1], measurement[0])
  end

  def reset_old_hash_to_bson
    Hash.class_eval <<-EVAL
      def to_bson(encoded = ''.force_encoding(BSON::BINARY))
        encode_bson_with_placeholder(encoded) do |encoded|
          each do |field, value|
            encoded << value.bson_type
            field.to_bson_cstring(encoded)
            value.to_bson(encoded)
          end
        end
      end
    EVAL
  end

  def set_new_hash_to_bson(version = 0)
    if version == 0
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
            encode_bson_with_placeholder(encoded) do |encoded|
              each do |field, value|
                encoded << value.bson_type
                encoded << _memo_set(field) { field.to_bson_cstring }
                value.to_bson(encoded)
              end
            end
          else
            encode_bson_with_placeholder(encoded) do |encoded|
              each do |field, value|
                encoded << value.bson_type
                encoded << _memo_fetch(field) { field.to_bson_cstring }
                value.to_bson(encoded)
              end
            end
          end
        end
      EVAL
    else
      Hash.class_eval <<-EVAL
          @@_memo_hash = Hash.new
          def _memo(field)
            @@_memo_hash[field] = @@_memo_hash.fetch(field) { yield }
          end
          def to_bson(encoded = ''.force_encoding(BSON::BINARY))
            encode_bson_with_placeholder(encoded) do |encoded|
              each do |field, value|
                encoded << value.bson_type
                encoded << _memo(field) { field.to_bson_cstring }
                value.to_bson(encoded)
              end
            end
          end
      EVAL
    end
  end

  def test_symbol_key_optimization
    size = 1024
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s).to_sym, i]}.flatten]

    measurement = []
    Benchmark.bm(@label_width) do |bench|

      reset_old_hash_to_bson
      measurement << bench.report('Symbol key optimize none') do
        @count.times { hash.to_bson }
      end

      set_new_hash_to_bson(0)
      measurement << bench.report('Symbol key optimize hash key v0') do
        @count.times { hash.to_bson }
      end

      set_new_hash_to_bson(1)
      measurement << bench.report('Symbol key optimize hash key v1') do
        @count.times { hash.to_bson }
      end

      reset_old_hash_to_bson
    end
    print_gain(measurement[1], measurement[0])
    print_gain(measurement[2], measurement[0])
  end

  def test_string_key_optimization
    size = 1024
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i]}.flatten]

    measurement = []
    Benchmark.bm(@label_width) do |bench|

      reset_old_hash_to_bson
      measurement << bench.report('String key optimize none') do
        @count.times { hash.to_bson }
      end

      set_new_hash_to_bson(0)
      measurement << bench.report('String key optimize hash v0') do
        @count.times { hash.to_bson }
      end

      set_new_hash_to_bson(1)
      measurement << bench.report('String key optimize hash v1') do
        @count.times { hash.to_bson }
      end

      reset_old_hash_to_bson
    end
    print_gain(measurement[1], measurement[0])
    print_gain(measurement[2], measurement[0])
  end

  def reset_integer_bson_int32?
    Integer.class_eval <<-EVAL
      def bson_int32?
        (MIN_32BIT <= self) && (self <= MAX_32BIT)
      end
    EVAL
  end

  def set_new_integer_bson_int32?
    Integer.class_eval <<-EVAL
      @@FIXNUM_HIGHBITS32 = (-1 << 32)
      def bson_int32?
        (self & @@FIXNUM_HIGHBITS32) == 0
      end
    EVAL
  end

  def test_bson_int32?
    count = 100_000_000
    measurement = []
    Benchmark.bm(@label_width) do |bench|

      reset_integer_bson_int32?
      measurement << bench.report('Integer#bson_int32? old') do
        count.times {|i| i.bson_int32? }
      end

      set_new_integer_bson_int32?
      measurement << bench.report('Integer#bson_int32? new') do
        count.times {|i| i.bson_int32? }
      end

      reset_integer_bson_int32?
    end
    print_gain(measurement[1], measurement[0])
  end

  def test_ruby_prof
    json_filename = '../../../training/data/sampledata/twitter.json'
    line_limit = 10_000
    twitter = nil
    File.open(json_filename, 'r') do |f|
      twitter = line_limit.times.collect { JSON.parse(f.gets) }
    end

    result = nil
    Benchmark.bm(@label_width) do |bench|
      bench.report('test ruby prof') do

        RubyProf.start
        twitter.each {|doc| doc.to_bson }
        result = RubyProf.stop

      end
    end

    File.open('ruby-prof.out', 'w') do |f|
      RubyProf::FlatPrinter.new(result).print(f)
      RubyProf::GraphPrinter.new(result).print(f, {})
    end
  end

end

