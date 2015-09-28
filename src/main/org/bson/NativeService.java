/*
 * Copyright (C) 2009-2015 MongoDB, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.bson;

import java.io.IOException;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.runtime.load.BasicLibraryService;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;

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
   * Constant for the BSON module name.
   *
   * @since 2.0.0
   */
  private final String BYTE_BUF = "ByteBuff".intern();

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

    RubyClass byteBuffer = bson.defineClassUnder("ByteBuffer", runtime.getObject(), new ObjectAllocator() {
      public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
        return new ByteBuf(runtime, rubyClass);
      }
    });

    byteBuffer.defineAnnotatedMethods(ByteBuf.class);

    return true;
  }
}
