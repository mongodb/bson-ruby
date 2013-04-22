package org.bson;

import java.io.IOException;

import org.jruby.Ruby;
import org.jruby.RubyModule;
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
   * Example: service.basicLoad(ruby);
   *
   * @param runtime The Ruby runtime.
   *
   * @return Always returns true if no exception.
   *
   * @since 2.0.0
   */
  public boolean basicLoad(Ruby runtime) throws IOException {
    RubyModule bson = runtime.fastGetModule(BSON);
    new IntegerExtension(runtime, bson).redefine();
    return true;
  }

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
    private final String INTEGER = "Integer".intern();

    /**
     * The Ruby runtime for the service.
     *
     * @since 2.0.0.
     */
    private final Ruby runtime;

    /**
     * The service's integer module to operate on.
     *
     * @since 2.0.0
     */
    private final RubyModule integer;

    /**
     * Instantiate a new integer extender.
     *
     * @param runtime The Ruby runtime.
     * @param bson The parent BSON module.
     *
     * @since 2.0.0.
     */
    private IntegerExtension(final Ruby runtime, final RubyModule bson) {
      this.runtime = runtime;
      this.integer = bson.defineOrGetModuleUnder(INTEGER);
    }

    /**
     * Load the method definitions into the integer module.
     *
     * @since 2.0.0.
     */
    public void redefine() {
      integer.defineAnnotatedMethods(IntegerExtension.class);
    }

    /**
     * Encodes the integer to the raw BSON bytes.
     *
     * @param bytes The encoded bytes to append to.
     *
     * @return The encoded bytes.
     *
     * @since 2.0.0.
     */
    @JRubyMethod(name = "to_bson") public IRubyObject toBson(IRubyObject bytes) {
      return bytes;
    }

    /**
     * Encodes the integer to the raw BSON bytes.
     *
     * @return The encoded bytes.
     *
     * @since 2.0.0.
     */
    @JRubyMethod(name = "to_bson") public IRubyObject toBson() {
      return RubyString.newEmptyString(runtime);
    }
  }
}
