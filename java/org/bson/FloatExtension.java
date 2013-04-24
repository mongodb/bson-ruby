package org.bson;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

import org.jruby.Ruby;
import org.jruby.RubyFloat;
import org.jruby.RubyModule;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Provides native extensions around float operations.
 *
 * @since 2.0.0
 */
public class FloatExtension {

  /**
   * Constant for the Float module name.
   *
   * @since 2.0.0
   */
  private static final String FLOAT = "Float".intern();

  /**
   * Load the method definitions into the float module.
   *
   * @param bson The bson module to define the methods under.
   *
   * @since 2.0.0.
   */
  public static void extend(final RubyModule bson) {
    RubyModule floatMod = bson.defineOrGetModuleUnder(FLOAT);
    floatMod.defineAnnotatedMethods(FloatExtension.class);
  }

  /**
   * Encodes the float to the raw BSON bytes.
   *
   * @param float The instance of the float object.
   *
   * @return The encoded bytes.
   *
   * @since 2.0.0.
   */
  @JRubyMethod(name = "to_bson")
  public static IRubyObject toBson(final IRubyObject number) {
    final double value = ((RubyFloat) number).getDoubleValue();
    return toBsonDouble(number.getRuntime(), value);
  }

  /**
   * Encodes the float to the raw BSON bytes.
   *
   * @param float The instance of the float object.
   * @param bytes The bytes to encode to.
   *
   * @return The encoded bytes.
   *
   * @since 2.0.0.
   */
  @JRubyMethod(name = "to_bson")
  public static IRubyObject toBson(final IRubyObject number, final IRubyObject bytes) {
    final double value = ((RubyFloat) number).getDoubleValue();
    return ((RubyString) bytes).append(toBsonDouble(number.getRuntime(), value));
  }

  /**
   * Take the double value and convert it to it's little endian bytes.
   *
   * @param runtime The JRuby runtime.
   * @param value The value to encode.
   *
   * @return The byte array.
   *
   * @since 2.0.0.
   */
  private static RubyString toBsonDouble(final Ruby runtime, final double value) {
    final ByteBuffer buffer = ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN);
    buffer.putDouble(value);
    return RubyString.newString(runtime, buffer.array());
  }
}
