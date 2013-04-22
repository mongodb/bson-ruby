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
   * Constant for the Integer module name.
   *
   * @since 2.0.0
   */
  private final String INTEGER = "Integer".intern();

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
    RubyModule integer = bson.defineOrGetModuleUnder(INTEGER);
    return true;
  }
}
