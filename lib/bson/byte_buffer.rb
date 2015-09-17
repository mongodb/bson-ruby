# Copyright (C) 2015 MongoDB Inc.
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

module BSON
  class ByteBuffer

    # Initialize the pure ruby byte buffer.
    #
    # @example Create the buffer.
    #   BSON::ByteBuffer.new
    #
    # @since 4.0.0
    def initialize
      @buffer = "".force_encoding(BINARY)
    end

    # Get the length of the buffer.
    #
    # @example Get the length of the buffer.
    #   buffer.length
    #
    # @return [ Integer ] The buffer length.
    #
    # @since 4.0.0
    def length
      @buffer.bytesize
    end

    # Put a single byte on the end of the buffer.
    #
    # @example Put a single byte on the buffer.
    #   buffer.put_byte(4)
    #
    # @param [ Integer ] value The byte to append.
    #
    # @return [ ByteBuffer ] The modified buffer.
    #
    # @since 4.0.0
    def put_byte(value)
      @buffer << value
      self
    end

    # Put a null termintated c string on the end of the buffer.
    #
    # @example Put a cstring.
    #   buffer.put_cstring('test')
    #
    # @param [ String ] value The string.
    #
    # @return [ ByteBuffer ] The modified buffer.
    #
    # @since 4.0.0
    def put_cstring(value)
      @buffer << value << NULL_BYTE
      self
    end

    # Put a 64 bit double on the buffer.
    #
    # @example Put a double.
    #   buffer.put_double(213.11231)
    #
    # @param [ Float ] value The float to convert.
    #
    # @return [ ByteBuffer ] The modified buffer.
    #
    # @since 4.0.0
    def put_double(value)
      @buffer << [ value ].pack(Float::PACK)
      self
    end

    # Put a 32 bit integer on the end of the buffer.
    #
    # @example Put a 32 bit integer on the buffer.
    #   buffer.put_int32(4)
    #
    # @param [ Integer ] value The integer.
    #
    # @return [ ByteBuffer ] The modified buffer.
    #
    # @since 4.0.0
    def put_int32(value)
      @buffer << [ value ].pack(Int32::PACK)
      self
    end

    # Put a 64 bit integer on the end of the buffer.
    #
    # @example Put a 64 bit integer on the buffer.
    #   buffer.put_int64(4)
    #
    # @param [ Integer ] value The integer.
    #
    # @return [ ByteBuffer ] The modified buffer.
    #
    # @since 4.0.0
    def put_int64(value)
      @buffer << [ value ].pack(Int64::PACK)
      self
    end

    # Put a string on the end of the buffer.
    #
    # @example Put a string on the buffer.
    #   buffer.put_string('test')
    #
    # @param [ String ] value The value to append.
    #
    # @return [ ByteBuffer ] The modified buffer.
    #
    # @since 4.0.0
    def put_string(value)
      put_int32(value.bytesize + 1)
      @buffer << value
      @buffer << NULL_BYTE
      self
    end

    # Replace an int 32 at the specified location in the buffer.
    #
    # @example Replace an int 32.
    #   buffer.replace_int32(4, 32)
    #
    # @param [ Integer ] index The index to replace at.
    # @param [ Integer ] value The new value.
    #
    # @return [ ByteBuffer ] The modified buffer.
    #
    # @since 4.0.0
    def replace_int32(location, value)
      @buffer[location, Int32::BYTES_LENGTH] = [ value ].pack(Int32::PACK)
      self
    end

    def to_s
      @buffer
    end
  end
end
