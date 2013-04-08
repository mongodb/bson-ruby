$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'bson'
require 'test/unit'
require 'benchmark'
require 'ruby-prof'

#example usage
# @@_KEY_MEMO_MAX_SIZE = 4096
# @@_key_memo = Memo.new(@@_KEY_MEMO_MAX_SIZE)
# def to_bson_cstring(encoded = ''.force_encoding(BINARY))
#   encoded << @@_key_memo.memo(key) do
#     key.send(:check_for_illegal_characters!)
#     key.to_bson_string << BSON::NULL_BYTE
#   end
# end

class Memo

  def initialize(size = nil)
    @max_size = size
    @mutex = Mutex.new
    @map = Hash.new
  end

  def memo(key)
    @mutex.synchronize do
      value = @map.fetch(key, nil) || yield
      (@max_size == nil || @map.size < @max_size) ? @map[key] = value : value
    end
  end

end

class BenchTest < Test::Unit::TestCase

  def setup
    @count = 10 #10_000
    @label_width = 28
  end

  def test_array_index_optimization
    size = 1024
    array = Array.new(size){|i| i}
    Benchmark.bm(@label_width) do |bench|
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
      [
         [ 'Array index optimize none',    0 ], # user 55 sec
         [ 'Array index optimize 1000', 1000 ]  # user 31 sec - purposely test less than 1024 ()@@_INDEX_OPTIM_SIZE)
      ].each do |label, _bson_index_size|
        Array.class_variable_set(:@@_BSON_INDEX_SIZE, _bson_index_size)
        bench.report(label) do
          @count.times { array.to_bson }
        end
      end
    end
  end

  def test_symbol_key_optimization
    size = 1024
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s).to_sym, i]}.flatten]

    Benchmark.bm(@label_width) do |bench|
      # old code - user 161 sec
      bench.report('Symbol key optimize none') do
        @count.times { hash.to_bson }
      end

      # new code - user 49 sec
      Symbol.class_eval <<-EVAL
        @@_bson_map = Hash.new {|h, k| h[k] = k.to_s.to_bson_cstring }
        @@_bson_map_mutex = Mutex.new
        def to_bson_cstring(encoded = ''.force_encoding(BSON::BINARY))
          encoded << @@_bson_map_mutex.synchronize { @@_bson_map[self] }
        end
      EVAL
      bench.report('Symbol key optimize map') do
        @count.times { hash.to_bson }
      end
      #p Symbol.class_variable_get(:@@_bson_map)

      # new code - user 49 sec
      Symbol.class_eval <<-EVAL
        @@_bson_memo = Memo.new
        def to_bson_cstring(encoded = ''.force_encoding(BSON::BINARY))
          encoded << @@_bson_memo.memo(self) { to_s.to_bson_cstring }
        end
      EVAL
      bench.report('Symbol key optimize map') do
        @count.times { hash.to_bson }
      end
      #p Symbol.class_variable_get(:@@_bson_memo)

    end
  end

  def test_string_key_optimization
    size = 4096
    hash = Hash[*(0..size).to_a.collect{|i| [ ('a' + i.to_s), i]}.flatten]

    Benchmark.bm(@label_width) do |bench|
      # old code - user 161 sec
      bench.report('String key optimize none') do
        @count.times { hash.to_bson }
      end

      # new code - user 116 sec
      String.class_eval <<-EVAL
        @@_BSON_MAP_SIZE = 4096
        @@_bson_map_mutex = Mutex.new
        @@_bson_map = Hash.new do |h, k|
          k.send(:check_for_illegal_characters!)
          bson_key = k.to_bson_string << BSON::NULL_BYTE
          h.size < @@_BSON_MAP_SIZE ? h[k] = bson_key : bson_key
        end
        def to_bson_cstring(encoded = ''.force_encoding(BSON::BINARY))
          encoded << @@_bson_map_mutex.synchronize { @@_bson_map[self] }
        end
      EVAL
      bench.report('String key optimize map') do
        @count.times { hash.to_bson }
      end
      #p String.class_variable_get(:@@_bson_map)

      # new code - user 49 sec
      String.class_eval <<-EVAL
        @@_BSON_MAP_SIZE = 4096
        @@_bson_memo = Memo.new(@@_BSON_MAP_SIZE)
        def to_bson_cstring(encoded = ''.force_encoding(BSON::BINARY))
          encoded << @@_bson_memo.memo(self) do
            self.send(:check_for_illegal_characters!)
            self.to_bson_string << BSON::NULL_BYTE
          end
        end
      EVAL
      bench.report('Symbol key optimize map') do
        @count.times { hash.to_bson }
      end
      #p Symbol.class_variable_get(:@@_bson_memo)
    end
  end

end

