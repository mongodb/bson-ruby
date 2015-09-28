/*
 * Copyright (C) 2015 MongoDB, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.bson;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;

import org.jruby.Ruby;
import org.jruby.RubyBignum;
import org.jruby.RubyClass;
import org.jruby.RubyFloat;
import org.jruby.RubyFixnum;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Provides native extensions around boolean operations.
 *
 * @since 4.0.0
 */
public class ByteBuf extends RubyObject {

  private static byte NULL_BYTE = 0x00;

  /**
   * The modes for the buffer.
   */
  private enum Mode { READ, WRITE }

  /**
   * The wrapped byte buffer.
   */
  private ByteBuffer buffer;

  /**
   * The current buffer mode.
   */
  private Mode mode;

  /**
   * The current position while reading.
   */
  private int readPosition = 0;

  /**
   * The current position while writing.
   */
  private int writePosition = 0;

  /**
   * Instantiate the ByteBuf.
   */
  public ByteBuf(final Ruby runtime, final RubyClass rubyClass) {
    super(runtime, rubyClass);
  }

  @JRubyMethod(name = "initialize")
  public IRubyObject intialize() {
    this.buffer = ByteBuffer.allocate(1024).order(ByteOrder.LITTLE_ENDIAN);
    this.mode = Mode.WRITE;
    return null;
  }

  @JRubyMethod(name = "initialize")
  public IRubyObject initialize(final RubyString value) {
    this.buffer = ByteBuffer.wrap(value.getBytes()).order(ByteOrder.LITTLE_ENDIAN);
    this.mode = Mode.READ;
    return null;
  }

  @JRubyMethod(name = "get_byte")
  public RubyString getByte() {
    ensureBsonRead();
    RubyString string = RubyString.newString(getRuntime(), new byte[] { this.buffer.get() });
    this.readPosition += 1;
    return string;
  }

  @JRubyMethod(name = "get_bytes")
  public RubyString getBytes(final IRubyObject value) {
    ensureBsonRead();
    int length = RubyNumeric.fix2int((RubyFixnum) value);
    ByteBuffer buff = this.buffer.get(new byte[length]);
    RubyString string = RubyString.newString(getRuntime(), buff.array());
    this.readPosition += length;
    return string;
  }

  @JRubyMethod(name = "get_double")
  public RubyFloat getDouble() {
    ensureBsonRead();
    RubyFloat doubl = new RubyFloat(getRuntime(), this.buffer.getDouble());
    this.readPosition += 8;
    return doubl;
  }

  @JRubyMethod(name = "get_int32")
  public RubyFixnum getInt32() {
    ensureBsonRead();
    RubyFixnum int32 = new RubyFixnum(getRuntime(), this.buffer.getInt());
    this.readPosition += 4;
    return int32;
  }

  @JRubyMethod(name = "get_string")
  public RubyString getString() {
    ensureBsonRead();
    int length = this.buffer.getInt();
    this.readPosition += 4;
    byte[] stringBytes = new byte[length];
    this.buffer.get(stringBytes);
    byte[] bytes = Arrays.copyOfRange(stringBytes, 0, stringBytes.length - 1);
    RubyString string = RubyString.newString(getRuntime(), bytes);
    this.readPosition += length;
    return string;
  }

  @JRubyMethod(name = "get_int64")
  public RubyBignum getInt64() {
    ensureBsonRead();
    RubyBignum int64 = new RubyBignum(getRuntime(), RubyBignum.long2big(this.buffer.getLong()));
    this.readPosition += 8;
    return int64;
  }

  @JRubyMethod(name = "put_byte")
  public ByteBuf putByte(final IRubyObject value) {
    ensureBsonWrite();
    this.buffer.put(((RubyString) value).getBytes()[0]);
    this.writePosition += 1;
    return this;
  }

  @JRubyMethod(name = "put_bytes")
  public ByteBuf putBytes(final IRubyObject value) {
    ensureBsonWrite();
    byte[] bytes = ((RubyString) value).getBytes();
    this.buffer.put(bytes);
    this.writePosition += bytes.length;
    return this;
  }

  @JRubyMethod(name = "put_double")
  public ByteBuf putDouble(final IRubyObject value) {
    ensureBsonWrite();
    this.buffer.putDouble(((RubyFloat) value).getDoubleValue());
    this.writePosition += 8;
    return this;
  }

  @JRubyMethod(name = "put_int32")
  public ByteBuf putInt32(final IRubyObject value) {
    ensureBsonWrite();
    this.buffer.putInt(RubyNumeric.fix2int((RubyFixnum) value));
    this.writePosition += 4;
    return this;
  }

  @JRubyMethod(name = "put_int64")
  public ByteBuf putInt64(final IRubyObject value) {
    ensureBsonWrite();
    this.buffer.putLong(RubyNumeric.fix2long((RubyFixnum) value));
    this.writePosition += 8;
    return this;
  }

  @JRubyMethod(name = "put_string")
  public ByteBuf putString(final IRubyObject value) {
    ensureBsonWrite();
    byte[] bytes = ((RubyString) value).getBytes();
    this.buffer.putInt(bytes.length + 1);
    this.buffer.put(bytes);
    this.buffer.put(NULL_BYTE);
    this.writePosition += (bytes.length + 5);
    return this;
  }

  @JRubyMethod(name = "read_position")
  public RubyFixnum getReadPosition() {
    return new RubyFixnum(getRuntime(), this.readPosition);
  }

  @JRubyMethod(name = "write_position")
  public RubyFixnum getWritePosition() {
    return new RubyFixnum(getRuntime(), this.writePosition);
  }

  /**
   * Convert the byte buffer to a string of the bytes.
   */
  @JRubyMethod(name = "to_s")
  public RubyString toRubyString() {
    ensureBsonRead();
    byte[] bytes = new byte[this.writePosition];
    this.buffer.get(bytes, 0, this.writePosition);
    return RubyString.newString(getRuntime(), bytes);
  }

  private void ensureBsonRead() {
    if (this.mode == Mode.WRITE) {
      this.buffer.flip();
    }
  }

  /**
   * This will grow the underlying byte buffer if the remaining size is too small.
   */
  private void ensureBsonWrite() {
    if (this.mode == Mode.READ) {
      this.buffer.flip();
    }
    // if size of item > limit, increase the buffer.
  }
}
