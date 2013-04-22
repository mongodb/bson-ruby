package org.bson;

import java.io.IOException;

import org.jruby.Ruby;
import org.jruby.RubyModule;
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
   * The Ruby runtime as the root to all extensions.
   *
   * @since 2.0.0
   */
  private Ruby runtime;

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
    this.runtime = runtime;
    RubyModule bson = runtime.fastGetModule(BSON);
    new IntegerExtender(bson).define();
    return true;
  }

  /**
   * Provides native extensions around integer operations.
   *
   * @since 2.0.0
   */
  private class IntegerExtender {

    /**
     * Constant for the Integer module name.
     *
     * @since 2.0.0
     */
    private final String INTEGER = "Integer".intern();

    /**
     * The service's integer module to operate on.
     *
     * @since 2.0.0
     */
    private RubyModule integer;

    /**
     * Instantiate a new integer extender.
     *
     * @param bson The parent BSON module.
     *
     * @since 2.0.0.
     */
    private IntegerExtender(final RubyModule bson) {
      this.integer = bson.defineOrGetModuleUnder(INTEGER);
    }

    /**
     * Load the method definitions into the integer module.
     *
     * @return True if the loading was successful.
     *
     * @since 2.0.0.
     */
    public boolean define() {
      return true;
    }
  }
}
