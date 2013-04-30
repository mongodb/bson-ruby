package org.bson;

import java.math.BigInteger;

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
   * Constant for the string module name.
   *
   * @since 2.0.0
   */
  private static final String STRING = "String".intern();

  /**
   * Load the method definitions into the string module.
   *
   * @param bson The bson module to define the methods under.
   *
   * @since 2.0.0
   */
  public static void extend(final RubyModule bson) {
    RubyModule string = bson.defineOrGetModuleUnder(STRING);
    string.defineAnnotatedMethods(StringExtension.class);
  }
}
