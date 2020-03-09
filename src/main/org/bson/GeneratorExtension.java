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

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
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
   * The integer representation of the unique machine id.
   *
   * @since 2.0.0
   */
  private static int machineId = new MachineId().value();

  /**
   * Load the method definitions into the generator class.
   *
   * @param bson The bson module to define the methods under.
   *
   * @since 2.0.0
   */
  public static void extend(final RubyModule bson) {
    RubyClass objectId = bson.fastGetClass(OBJECT_ID);
    RubyClass generator = objectId.fastGetClass(GENERATOR);
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
  @JRubyMethod(name = "next")
  public static IRubyObject next(final IRubyObject generator) {
    return nextObjectId(generator, (int) System.currentTimeMillis() / 1000);
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
  @JRubyMethod(name = "next")
  public static IRubyObject next(final IRubyObject generator, final IRubyObject time) {
    return nextObjectId(generator, (int) ((RubyInteger) time).getLongValue() / 1000);
  }

  /**
   * Generate the next object id in the sequence.
   *
   * @param generator The object id generator.
   * @param time The time in seconds.
   *
   * @return The object id raw bytes.
   *
   * @since 2.0.0
   */
  private static IRubyObject nextObjectId(final IRubyObject generator, final int time) {
    final ByteBuffer buffer = ByteBuffer.allocate(12).order(ByteOrder.BIG_ENDIAN);
    buffer.putInt(time).putInt(machineId).putInt(counter.getAndIncrement());
    return RubyString.newString(generator.getRuntime(), buffer.array());
  }
}
