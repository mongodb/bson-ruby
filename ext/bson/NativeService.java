package org.bson;

import java.io.IOException;

import org.jruby.Ruby;
import org.jruby.RubyModule;
import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
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
  public boolean basicLoad(Ruby runtime) throws IOException {
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
    public static IRubyObject toBson(IRubyObject integer) {
      // @todo: Durran: Implement.
      return RubyString.newEmptyString(integer.getRuntime());
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
    public static IRubyObject toBson(IRubyObject integer, IRubyObject bytes) {
      // @todo: Durran: Implement.
      return RubyString.newEmptyString(integer.getRuntime());
    }
  }
}
