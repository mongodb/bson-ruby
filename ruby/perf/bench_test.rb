$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'bson'
require 'test/unit'
require 'benchmark'
#require 'ruby-prof'

class BenchTest < Test::Unit::TestCase

  def setup
    puts
    @count = 10_000
    @label_width = 30
  end

  def teardown
    puts
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

  def print_gain(modification_tms, base_tms)
    puts "gain: #{'%.2f' % (1.0 - modification_tms.utime/base_tms.utime)} (#{base_tms.utime.round} --> #{modification_tms.utime.round})"
  end

  def test_array_index_optimization
    size = 1024
    array = Array.new(size){|i| i}

    Benchmark.bm(@label_width) do |bench|

      set_new_array_index_optimize
      measurement = [
         [ 'Array index optimize none',    0 ], # user Xeon 37 sec
         [ 'Array index optimize 1000', 1000 ]  # user Xeon 22 sec - 40% gain - purposely test less than 1024)
      ].collect do |label, _bson_index_size|
        Array.class_variable_set(:@@_BSON_INDEX_SIZE, _bson_index_size)
        bench.report(label) do
          @count.times { array.to_bson }
        end
      end

      print_gain(measurement[1], measurement[0])

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

      print_gain(measurement[1], measurement[0])
      print_gain(measurement[2], measurement[0])

    end
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

      print_gain(measurement[1], measurement[0])
      print_gain(measurement[2], measurement[0])

    end
  end

end

