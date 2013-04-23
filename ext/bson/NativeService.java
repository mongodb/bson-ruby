package org.bson;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

import org.jruby.Ruby;
import org.jruby.RubyModule;
import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.BasicLibraryService;

/**
 * The native implementation of various extensions.
 *
 * @since 2.0.0
 */
public class NativeService implements BasicLibraryService {

  /**
   * Constant for the BSON module name.
   *
   * @since 2.0.0
   */
  private final String BSON = "BSON".intern();

  /**
   * Loads the native extension into the JRuby runtime.
   *
   * @param runtime The Ruby runtime.
   *
   * @return Always returns true if no exception.
   *
   * @since 2.0.0
   */
  public boolean basicLoad(final Ruby runtime) throws IOException {
    RubyModule bson = runtime.fastGetModule(BSON);
    IntegerExtension.extend(bson);
    return true;
  }

  /**
   * Provides native extensions around integer operations.
   *
   * @since 2.0.0
   */
  public static class IntegerExtension {

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
     * @since 2.0.0.
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
     * @since 2.0.0.
     */
    @JRubyMethod(name = "to_bson")
    public static IRubyObject toBson(final IRubyObject integer) {
      final long value = ((RubyInteger) integer).getLongValue();
      return RubyString.newString(integer.getRuntime(), toBsonInt32(value));
    }

    /**
     * Encodes the integer to the raw BSON bytes.
     *
     * @param integer The instance of the integer object.
     * @param bytes The bytes to encode to.
     *
     * @return The encoded bytes.
     *
     * @since 2.0.0.
     */
    @JRubyMethod(name = "to_bson")
    public static IRubyObject toBson(final IRubyObject integer, final IRubyObject bytes) {
      final long value = ((RubyInteger) integer).getLongValue();
      final RubyString encoded =
        RubyString.newString(integer.getRuntime(), toBsonInt32(value));
      return ((RubyString) bytes).append(encoded);
    }

    /**
     * Take the 32bit value and convert it to it's little endian bytes.
     *
     * @param value The value to encode.
     *
     * @return The byte array.
     *
     * @since 2.0.0.
     */
    private static byte[] toBsonInt32(final long value) {
      final ByteBuffer buffer = ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN);
      buffer.putInt((int) value);
      return buffer.array();
    }

    /**
     * Take the 64bit value and convert it to it's little endian bytes.
     *
     * @param value The value to encode.
     *
     * @return The byte array.
     *
     * @since 2.0.0.
     */
    private static byte[] toBsonInt64(final long value) {
      final ByteBuffer buffer = ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN);
      buffer.putLong(value);
      return buffer.array();
    }
  }
}
