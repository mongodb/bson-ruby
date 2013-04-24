package org.bson;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

import org.jruby.Ruby;
import org.jruby.RubyModule;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Provides native extensions around string operations.
 *
 * @since 2.0.0
 */
public class StringExtension {

  /**
   * Constant for the String module name.
   *
   * @since 2.0.0
   */
  private static final String STRING = "String".intern();

  /**
   * Load the method definitions into the string module.
   *
   * @param bson The bson module to define the methods under.
   *
   * @since 2.0.0.
   */
  public static void extend(final RubyModule bson) {
    RubyModule string = bson.defineOrGetModuleUnder(STRING);
    string.defineAnnotatedMethods(StringExtension.class);
  }

  /**
   * Encodes the string to the raw BSON bytes.
   *
   * @param string The instance of the string object.
   *
   * @return The encoded bytes.
   *
   * @since 2.0.0.
   */
  @JRubyMethod(name = "to_bson")
  public static IRubyObject toBson(final IRubyObject string) {
    return null;
  }

  /**
   * Encodes the string to the raw BSON bytes.
   *
   * @param string The instance of the string object.
   * @param bytes The bytes to encode to.
   *
   * @return The encoded bytes.
   *
   * @since 2.0.0.
   */
  @JRubyMethod(name = "to_bson")
  public static IRubyObject toBson(final IRubyObject string, final IRubyObject bytes) {
    return null;
  }
}
