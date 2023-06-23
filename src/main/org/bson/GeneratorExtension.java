/*
 * Copyright (C) 2009-2020 MongoDB Inc.
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

import java.lang.ProcessHandle;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.security.SecureRandom;
import java.util.Random;
import java.util.concurrent.atomic.AtomicInteger;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyInteger;
import org.jruby.RubyModule;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Provides native extensions around object id generator operations.
 *
 * @since 2.0.0
 */
public class GeneratorExtension {

  /**
   * Constant for the BSON module name..
   *
   * @since 2.0.0
   */
  private static final String BSON = "BSON".intern();

  /**
   * Constant for the ObjectId module name.
   *
   * @since 2.0.0
   */
  private static final String OBJECT_ID = "ObjectId".intern();

  /**
   * Constant for the Generator class name.
   *
   * @since 2.0.0
   */
  private static final String GENERATOR = "Generator".intern();

  /**
   * The thread safe counter for the last 3 object id bytes.
   *
   * @since 2.0.0
   */
  private static AtomicInteger counter = new AtomicInteger(new Random().nextInt());

  /**
   * A random value, unique to this process.
   */
  private static byte[] randomValue = new byte[5];

  /**
   * The process id for the process that last generated the randomValue.
   */
  private static long pid = 0;

  /**
   * Load the method definitions into the generator class.
   *
   * @param bson The bson module to define the methods under.
   *
   * @since 2.0.0
   */
  public static void extend(final RubyModule bson) {
    RubyClass objectId = bson.getClass(OBJECT_ID);
    RubyClass generator = objectId.getClass(GENERATOR);
    generator.defineAnnotatedMethods(GeneratorExtension.class);
  }

  /**
   * Get the next object id in the sequence.
   *
   * @param generator The generator instance.
   *
   * @return The encoded bytes.
   *
   * @since 2.0.0
   */
  @JRubyMethod(name = { "next", "next_object_id" })
  public static IRubyObject next(final IRubyObject generator) {
    RubyModule bson = generator.getRuntime().getModule(BSON);
    RubyClass objectId = bson.getClass(OBJECT_ID);
    RubyInteger time = (RubyInteger) objectId.callMethod("timestamp");
    return nextObjectId(generator, (int) time.getLongValue());
  }

  /**
   * Get the next object id in the sequence.
   *
   * @param generator The generator instance.
   * @param time The time to generate at.
   *
   * @return The encoded bytes.
   *
   * @since 2.0.0
   */
  @JRubyMethod(name = { "next", "next_object_id" })
  public static IRubyObject next(final IRubyObject generator, final IRubyObject time) {
    return nextObjectId(generator, (int) ((RubyInteger) time).getLongValue() / 1000);
  }

  /**
   * Generate the next object id in the sequence, per the ObjectId spec:
   * https://github.com/mongodb/specifications/blob/master/source/objectid.rst#specification
   *
   * @param generator The object id generator.
   * @param time The time in seconds.
   *
   * @return The object id raw bytes.
   */
  private static IRubyObject nextObjectId(final IRubyObject generator, final int time) {
    final ByteBuffer buffer = ByteBuffer.allocate(12).order(ByteOrder.BIG_ENDIAN);

    // a 4-byte value representing the seconds since the Unix epoch in the highest order bytes,
    buffer.putInt(time);

    // a 5-byte random number unique to a machine and process,
    buffer.put(uniqueIdentifier());

    // a 3-byte counter, starting with a random value.
    buffer.put(counterBytes());

    return RubyString.newString(generator.getRuntime(), buffer.array());
  }

  /**
   * Get the 5-byte random number for the current process. If the value has
   * not yet been generated for the process, or if the process id has changed,
   * the value will be generated first.
   *
   * @return The 5-byte array
   */
  private static byte[] uniqueIdentifier() {
    final long currentPid = ProcessHandle.current().pid();

    if (currentPid != pid) {
      pid = currentPid;
      new SecureRandom().nextBytes(randomValue);
    }

    return randomValue;
  }

  /**
   * Get the next value of the counter as a 3-byte array (big-endian). This
   * will increment the counter.
   *
   * @return A 3-byte array representation of the next counter value.
   */
  private static byte[] counterBytes() {
    byte[] bytes = new byte[3];
    ByteBuffer buffer = ByteBuffer.allocate(4).order(ByteOrder.BIG_ENDIAN);

    buffer.putInt(counter.getAndIncrement() << 8);
    buffer.rewind();
    buffer.get(bytes);

    return bytes;
  }
}
