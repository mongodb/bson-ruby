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
import org.jruby.RubyModule;
import org.jruby.RubyString;
import org.jruby.RubyTime;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Provides native extensions around time operations.
 *
 * @since 2.0.0
 */
public class TimeExtension {

  /**
   * Constant for the time module name.
   *
   * @since 2.0.0
   */
  private static final String TIME = "Time".intern();

  /**
   * Load the method definitions into the time module.
   *
   * @param bson The bson module to define the methods under.
   *
   * @since 2.0.0
   */
  public static void extend(final RubyModule bson) {
    RubyModule time = bson.defineOrGetModuleUnder(TIME);
    time.defineAnnotatedMethods(TimeExtension.class);
  }

  /**
   * Encodes the time to the raw BSON bytes.
   *
   * @param time The instance of the time object.
   *
   * @return The encoded bytes.
   *
   * @since 2.0.0
   */
  @JRubyMethod(name = "to_bson")
  public static IRubyObject toBson(final IRubyObject time) {
    final long millis = ((RubyTime) time).getJavaDate().getTime();
    return toBsonTime(time.getRuntime(), millis);
  }

  /**
   * Encodes the time to the raw BSON bytes.
   *
   * @param time The instance of the time object.
   * @param bytes The bytes to encode to.
   *
   * @return The encoded bytes.
   *
   * @since 2.0.0
   */
  @JRubyMethod(name = "to_bson")
  public static IRubyObject toBson(final IRubyObject time, final IRubyObject bytes) {
    final long millis = ((RubyTime) time).getJavaDate().getTime();
    return ((RubyString) bytes).append(toBsonTime(time.getRuntime(), millis));
  }

  /**
   * Take the 64bit milliseconds and convert it to it's little endian bytes.
   *
   * @param runtime The JRuby runtime.
   * @param millis The milliseconds to encode.
   *
   * @return The byte array.
   *
   * @since 2.0.0
   */
  private static IRubyObject toBsonTime(final Ruby runtime, final long millis) {
    final ByteBuffer buffer = ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN);
    buffer.putLong(millis);
    return RubyString.newString(runtime, buffer.array());
  }
}
