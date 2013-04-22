package org.bson;

import java.io.IOException;

import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;

/**
 * The native implementation of various extensions.
 *
 * @since 2.0.0
 */
public class NativeService implements BasicLibraryService {

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
    return true;
  }
}
