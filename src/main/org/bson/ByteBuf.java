/*
 * Copyright (C) 2015-2016 MongoDB, Inc.
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

import java.io.ByteArrayOutputStream;
import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;

import org.jcodings.Encoding;
import org.jcodings.EncodingDB;

import org.jruby.Ruby;
import org.jruby.RubyBignum;
import org.jruby.RubyClass;
import org.jruby.RubyFloat;
import org.jruby.RubyFixnum;
import org.jruby.RubyInteger;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import java.math.BigInteger;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;

import static java.lang.String.format;

/**
 * Provides native extensions around boolean operations.
 *
 * @since 4.0.0
 */
public class ByteBuf extends RubyObject {

  /**
   * Constant for a null byte.
   */
  private static byte NULL_BYTE = 0x00;

  /**
   * The default size of the buffer.
   */
  private static int DEFAULT_SIZE = 1024;

  /**
   * The UTF-8 String.
   */
  private static String UTF8 = "UTF-8".intern();

  /**
   * Constant for UTF-8 encoding.
   */
  private static Encoding UTF_8 = EncodingDB.getEncodings().get(UTF8.getBytes()).getEncoding();

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
   * Instantiate the ByteBuf - this is #allocate in Ruby.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  public ByteBuf(final Ruby runtime, final RubyClass rubyClass) {
    super(runtime, rubyClass);
  }

  /**
   * Initialize an empty buffer.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "initialize")
  public IRubyObject intialize() {
    this.buffer = ByteBuffer.allocate(DEFAULT_SIZE).order(ByteOrder.LITTLE_ENDIAN);
    this.mode = Mode.WRITE;
    return null;
  }

  /**
   * Instantiate the buffer with bytes.
   *
   * @param value The bytes to instantiate with.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "initialize")
  public IRubyObject initialize(final RubyString value) {
    this.buffer = ByteBuffer.wrap(value.getBytes()).order(ByteOrder.LITTLE_ENDIAN);
    this.mode = Mode.READ;
    return null;
  }

  /**
   * Get a single byte from the buffer.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "get_byte")
  public RubyString getByte() {
    ensureBsonRead();
    RubyString string = RubyString.newString(getRuntime(), new byte[] { this.buffer.get() });
    this.readPosition += 1;
    return string;
  }

  /**
   * Get the supplied number of bytes from the buffer.
   *
   * @param value The number of bytes to read.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "get_bytes")
  public RubyString getBytes(final IRubyObject value) {
    ensureBsonRead();
    int length = RubyNumeric.fix2int((RubyFixnum) value);
    byte[] bytes = new byte[length];
    ByteBuffer buff = this.buffer.get(bytes);
    RubyString string = RubyString.newString(getRuntime(), bytes);
    this.readPosition += length;
    return string;
  }

  /**
   * Get a cstring from the buffer.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "get_cstring")
  public RubyString getCString() {
    ensureBsonRead();
    ByteArrayOutputStream bytes = new ByteArrayOutputStream();
    byte next = NULL_BYTE;
    while((next = this.buffer.get()) != NULL_BYTE) {
      bytes.write(next);
    }
    RubyString string = getUTF8String(bytes.toByteArray());
    this.readPosition += (bytes.size() + 1);
    return string;
  }

  /**
   * Get the 16 bytes representing the decimal128 from the buffer.
   *
   * @author Emily Stolfo
   * @since 2016.03.24
   * @version 4.1.0
   */
  @JRubyMethod(name = "get_decimal128_bytes")
  public RubyString getDecimal128Bytes() {
    return getBytes(new RubyFixnum(getRuntime(), 16));
  }

  /**
   * Get a double from the buffer.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "get_double")
  public RubyFloat getDouble() {
    ensureBsonRead();
    RubyFloat doubl = new RubyFloat(getRuntime(), this.buffer.getDouble());
    this.readPosition += 8;
    return doubl;
  }

  /**
   * Get a 32 bit integer from the buffer.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "get_int32")
  public RubyFixnum getInt32() {
    ensureBsonRead();
    RubyFixnum int32 = new RubyFixnum(getRuntime(), this.buffer.getInt());
    this.readPosition += 4;
    return int32;
  }

  /**
   * Get a UTF-8 string from the buffer.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "get_string")
  public RubyString getString() {
    ensureBsonRead();
    int length = this.buffer.getInt();
    this.readPosition += 4;
    byte[] stringBytes = new byte[length];
    this.buffer.get(stringBytes);
    byte[] bytes = Arrays.copyOfRange(stringBytes, 0, stringBytes.length - 1);
    RubyString string = getUTF8String(bytes);
    this.readPosition += length;
    return string;
  }

  /**
   * Get a 64 bit integer from the buffer.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "get_int64")
  public RubyFixnum getInt64() {
    ensureBsonRead();
    RubyFixnum int64 = new RubyFixnum(getRuntime(), this.buffer.getLong());
    this.readPosition += 8;
    return int64;
  }

  /**
   * Put a single byte onto the buffer.
   *
   * @param value The byte to write.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "put_byte")
  public ByteBuf putByte(ThreadContext context, final IRubyObject value) {
    RubyString string;
    try {
      string = (RubyString) value;
    } catch (ClassCastException e) {
      throw context.runtime.newArgumentError(e.toString());
    }
    ensureBsonWrite(1);
    this.buffer.put(string.getBytes()[0]);
    this.writePosition += 1;
    return this;
  }

  /**
   * Put raw bytes onto the buffer.
   *
   * @param value The bytes to write.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "put_bytes")
  public ByteBuf putBytes(ThreadContext context, final IRubyObject value) {
    RubyString string;
    try {
      string = (RubyString) value;
    } catch (ClassCastException e) {
      throw context.runtime.newArgumentError(e.toString());
    }
    byte[] bytes = string.getBytes();
    ensureBsonWrite(bytes.length);
    this.buffer.put(bytes);
    this.writePosition += bytes.length;
    return this;
  }

  /**
   * Put a cstring onto the buffer.
   *
   * @param value The cstring to write.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "put_cstring")
  public ByteBuf putCString(final IRubyObject value) throws UnsupportedEncodingException {

   if (value instanceof RubyFixnum) {
     RubyString str = ((RubyFixnum) value).to_s();
     String string = str.asJavaString();
     this.writePosition += writeCharacters(string, true);
   }
   else {
    String string = value.asJavaString();
    this.writePosition += writeCharacters(string, true);
   }

   return this;
  }

  /**
   * Put the decimal128 high and low bits on to the buffer.
   *
   * @param low The low 64 bits.
   * @param high The high 64 bits.
   *
   * @author Emily Stolfo
   * @since 2016.03.24
   * @version 4.1.0
   */
  @JRubyMethod(name = "put_decimal128")
  public ByteBuf putDecimal128(final IRubyObject low, final IRubyObject high) {
    ensureBsonWrite(16);
    BigInteger bigLow;
    BigInteger bigHigh;

    if (low instanceof RubyBignum) {
      bigLow = ((RubyBignum) low).getBigIntegerValue();
    } else {
      bigLow = ((RubyFixnum) low).getBigIntegerValue();
    }

    if (high instanceof RubyBignum) {
      bigHigh = ((RubyBignum) high).getBigIntegerValue();
    } else {
      bigHigh = ((RubyFixnum) high).getBigIntegerValue();
    }

    this.buffer.putLong(bigLow.longValue());
    this.writePosition += 8;

    this.buffer.putLong(bigHigh.longValue());
    this.writePosition += 8;
    return this;
  }

  /**
   * Put a double onto the buffer.
   *
   * @param value the double to write.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "put_double")
  public ByteBuf putDouble(final IRubyObject value) {
    ensureBsonWrite(8);
    this.buffer.putDouble(((RubyFloat) value).getDoubleValue());
    this.writePosition += 8;
    return this;
  }

  /**
   * Put a 32 bit integer onto the buffer.
   *
   * @param value The integer to write.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "put_int32")
  public ByteBuf putInt32(final IRubyObject value) {
    ensureBsonWrite(4);
    this.buffer.putInt(RubyNumeric.fix2int((RubyFixnum) value));
    this.writePosition += 4;
    return this;
  }

  /**
   * Put a 64 bit integer onto the buffer.
   *
   * @param value The integer to write.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "put_int64")
  public ByteBuf putInt64(final IRubyObject value) {
    ensureBsonWrite(8);
    this.buffer.putLong(((RubyInteger) value).getLongValue());
    this.writePosition += 8;
    return this;
  }

  /**
   * Put a symbol onto the buffer.
   *
   * @param value The UTF-8 string to write.
   *
   * @author Ben Lewis
   * @since 2017.04.19
   * @version 4.2.2
   */
  @JRubyMethod(name = "put_symbol")
  public ByteBuf putSymbol(final IRubyObject value) throws UnsupportedEncodingException {
    String string = ((RubySymbol) value).asJavaString();
    return putJavaString(string);
  }

  /**
   * Put a UTF-8 string onto the buffer.
   *
   * @param value The UTF-8 string to write.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "put_string")
  public ByteBuf putString(final IRubyObject value) throws UnsupportedEncodingException {
    String string = ((RubyString) value).asJavaString();
    return putJavaString(string);
  }

  /**
   * Replace a 32 bit integer at the provided index in the buffer.
   *
   * @param index The index to replace at.
   * @param value The value to replace with.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "replace_int32")
  public ByteBuf replaceInt32(final IRubyObject index, final IRubyObject value) {
    int i = RubyNumeric.fix2int((RubyFixnum) index);
    int int32 = RubyNumeric.fix2int((RubyFixnum) value);
    this.buffer.putInt(i, int32);
    return this;
  }

 /**
   * Reset the read position to the beginning of the byte buffer.
   *
   * @author Emily Stolfo
   * @since 2016.01.19
   * @version 4.0.1
   */
  @JRubyMethod(name = "rewind!")
  public ByteBuf rewind() {
    this.buffer.rewind();
    this.mode = Mode.READ;
    this.readPosition = 0;
    return this;
   }

  /**
   * Get the total length of the buffer.
   *
   * @author Durran Jordan
   * @since 2015.09.29
   * @version 4.0.0
   */
  @JRubyMethod(name = "length")
  public RubyFixnum getLength() {
    if (this.mode == Mode.WRITE) {
      return getWritePosition();
    } else {
      return new RubyFixnum(getRuntime(), this.buffer.remaining());
    }
  }

  /**
   * Get the read position of the buffer.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "read_position")
  public RubyFixnum getReadPosition() {
    return new RubyFixnum(getRuntime(), this.readPosition);
  }

  /**
   * Get the write position of the buffer.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "write_position")
  public RubyFixnum getWritePosition() {
    return new RubyFixnum(getRuntime(), this.writePosition);
  }

  /**
   * Convert the byte buffer to a string of the bytes.
   *
   * @author Durran Jordan
   * @since 2015.09.26
   * @version 4.0.0
   */
  @JRubyMethod(name = "to_s")
  public RubyString toRubyString() {
    ensureBsonRead();
    byte[] bytes = new byte[this.writePosition];
    this.buffer.get(bytes, 0, this.writePosition);
    return RubyString.newString(getRuntime(), bytes);
  }

  private RubyString getUTF8String(final byte[] bytes) {
    return RubyString.newString(getRuntime(), new ByteList(bytes, UTF_8));
  }

  private void ensureBsonRead() {
    if (this.mode == Mode.WRITE) {
      this.buffer.flip();
    }
  }

  private void ensureBsonWrite(int length) {
    if (this.mode == Mode.READ) {
      this.buffer.flip();
    }
    if (length > this.buffer.remaining()) {
      int size = (this.buffer.position() + length) * 2;
      ByteBuffer newBuffer = ByteBuffer.allocate(size).order(ByteOrder.LITTLE_ENDIAN);
      if (this.buffer.position() > 0) {
        byte [] existing = new byte[this.buffer.position()];
        this.buffer.rewind();
        this.buffer.get(existing);
        newBuffer.put(existing);
      }
      this.buffer = newBuffer;
    }
  }

  private void write(byte b) {
    ensureBsonWrite(1);
    this.buffer.put(b);
  }

  private int writeCharacters(final String string, final boolean checkForNull) {
    int len = string.length();
    int total = 0;

    for (int i = 0; i < len;) {
      int c = Character.codePointAt(string, i);

      if (checkForNull && c == 0x0) {
        throw getRuntime().newArgumentError(format("String %s is not a valid UTF-8 CString.", string));
      }

      if (c < 0x80) {
        write((byte) c);
        total += 1;
      } else if (c < 0x800) {
        write((byte) (0xc0 + (c >> 6)));
        write((byte) (0x80 + (c & 0x3f)));
        total += 2;
      } else if (c < 0x10000) {
        write((byte) (0xe0 + (c >> 12)));
        write((byte) (0x80 + ((c >> 6) & 0x3f)));
        write((byte) (0x80 + (c & 0x3f)));
        total += 3;
      } else {
        write((byte) (0xf0 + (c >> 18)));
        write((byte) (0x80 + ((c >> 12) & 0x3f)));
        write((byte) (0x80 + ((c >> 6) & 0x3f)));
        write((byte) (0x80 + (c & 0x3f)));
        total += 4;
      }

      i += Character.charCount(c);
    }

    write((byte) 0);
    total++;
    return total;
  }

  private ByteBuf putJavaString(final String string) {
    ensureBsonWrite(4);
    this.buffer.putInt(0);
    int length = writeCharacters(string, false);
    this.buffer.putInt(this.buffer.position() - length - 4, length);
    this.writePosition += (length + 4);
    return this;
  }
}
