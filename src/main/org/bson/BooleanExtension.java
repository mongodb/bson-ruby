/*
 * Copyright (C) 2013 10gen Inc.
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

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.RubyModule;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Provides native extensions around boolean operations.
 *
 * @since 2.0.0
 */
public class BooleanExtension {

  /**
   * Constant for the FalseClass module name.
   *
   * @since 2.0.0
   */
  private static final String FALSE_CLASS = "FalseClass".intern();

  /**
   * Constant for the TrueClass module name.
   *
   * @since 2.0.0
   */
  private static final String TRUE_CLASS = "TrueClass".intern();

  /**
   * Constant for a single false byte.
   *
   * @since 2.0.0
   */
  private static final byte FALSE_BYTE = 0;

  /**
   * Constant for a single true byte.
   *
   * @since 2.0.0
   */
  private static final byte TRUE_BYTE = 1;

  /**
   * Constant for the array of 1 false byte.
   *
   * @since 2.0.0
   */
  private static final byte[] FALSE_BYTES = new byte[] { FALSE_BYTE };

  /**
   * Constant for the array of 1 true byte.
   *
   * @since 2.0.0
   */
  private static final byte[] TRUE_BYTES = new byte[] { TRUE_BYTE };

  /**
   * Load the method definitions into the boolean module.
   *
   * @param bson The bson module to define the methods under.
   *
   * @since 2.0.0
   */
  public static void extend(final RubyModule bson) {
    RubyModule falseMod = bson.defineOrGetModuleUnder(FALSE_CLASS);
    RubyModule trueMod = bson.defineOrGetModuleUnder(TRUE_CLASS);
    falseMod.defineAnnotatedMethods(BooleanExtension.class);
    trueMod.defineAnnotatedMethods(BooleanExtension.class);
  }

  /**
   * Encodes the boolean to the raw BSON bytes.
   *
   * @param bool The instance of the boolean object.
   *
   * @return The encoded bytes.
   *
   * @since 2.0.0
   */
  @JRubyMethod(name = "to_bson")
  public static IRubyObject toBson(final IRubyObject bool) {
    return toBsonBoolean(bool);
  }

  /**
   * Encodes the boolean to the raw BSON bytes.
   *
   * @param bool The instance of the boolean object.
   * @param bytes The bytes to encode to.
   *
   * @return The encoded bytes.
   *
   * @since 2.0.0
   */
  @JRubyMethod(name = "to_bson")
  public static IRubyObject toBson(final IRubyObject bool, final IRubyObject bytes) {
    return ((RubyString) bytes).append(toBsonBoolean(bool));
  }

  /**
   * Take the boolean value and convert it to its bytes.
   *
   * @param bool The Ruby boolean value.
   *
   * @return The byte array.
   *
   * @since 2.0.0
   */
  private static RubyString toBsonBoolean(final IRubyObject bool) {
    final Ruby runtime = bool.getRuntime();
    if (bool == runtime.getTrue()) {
      return RubyString.newString(runtime, TRUE_BYTES);
    }
    else {
      return RubyString.newString(runtime, FALSE_BYTES);
    }
  }
}
