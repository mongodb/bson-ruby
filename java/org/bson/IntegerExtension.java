package org.bson;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

import org.jruby.Ruby;
import org.jruby.RubyModule;
import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Provides native extensions around integer operations.
 *
 * @since 2.0.0
 */
public class IntegerExtension {

  /**
   * Constant for the Integer module name.
   *
   * @since 2.0.0
   */
  private static final String INTEGER = "Integer".intern();

  /**
   * Load the method definitions into the integer module.
   *
   * @param bson The bson module to define the methods under.
   *
   * @since 2.0.0
   */
  public static void extend(final RubyModule bson) {
    RubyModule integer = bson.defineOrGetModuleUnder(INTEGER);
    integer.defineAnnotatedMethods(IntegerExtension.class);
  }

  /**
   * Encodes the integer to the raw BSON bytes.
   *
   * @param integer The instance of the integer object.
   *
   * @return The encoded bytes.
   *
   * @since 2.0.0
   */
  @JRubyMethod(name = "to_bson")
  public static IRubyObject toBson(final IRubyObject integer) {
    final long value = ((RubyInteger) integer).getLongValue();
    return toBsonInt(integer.getRuntime(), value);
  }

  /**
   * Encodes the integer to the raw BSON bytes.
   *
   * @param integer The instance of the integer object.
   * @param bytes The bytes to encode to.
   *
   * @return The encoded bytes.
   *
   * @since 2.0.0
   */
  @JRubyMethod(name = "to_bson")
  public static IRubyObject toBson(final IRubyObject integer, final IRubyObject bytes) {
    final long value = ((RubyInteger) integer).getLongValue();
    return ((RubyString) bytes).append(toBsonInt(integer.getRuntime(), value));
  }

  /**
   * Convert the integer to the raw bson.
   *
   * @param runtime The JRuby runtime.
   * @param value The integer value.
   *
   * @return The encoded bytes.
   *
   * @since 2.0.0
   */
  private static RubyString toBsonInt(final Ruby runtime, final long value) {
    return isInt32(value) ? toBsonInt32(runtime, value) : toBsonInt64(runtime, value);
  }

  /**
   * Determine if the integer is 32bit.
   *
   * @param value The integer value.
   *
   * @return If the integer is in 32bit range.
   *
   * @since 2.0.0
   */
  private static boolean isInt32(final long value) {
    return (Integer.MIN_VALUE <= value && value <= Integer.MAX_VALUE);
  }

  /**
   * Take the 32bit value and convert it to it's little endian bytes.
   *
   * @param runtime The JRuby runtime.
   * @param value The value to encode.
   *
   * @return The byte array.
   *
   * @since 2.0.0
   */
  private static RubyString toBsonInt32(final Ruby runtime, final long value) {
    final ByteBuffer buffer = ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN);
    buffer.putInt((int) value);
    return RubyString.newString(runtime, buffer.array());
  }

  /**
   * Take the 64bit value and convert it to it's little endian bytes.
   *
   * @param runtime The JRuby runtime.
   * @param value The value to encode.
   *
   * @return The byte array.
   *
   * @since 2.0.0
   */
  private static RubyString toBsonInt64(final Ruby runtime, final long value) {
    final ByteBuffer buffer = ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN);
    buffer.putLong(value);
    return RubyString.newString(runtime, buffer.array());
  }
}
