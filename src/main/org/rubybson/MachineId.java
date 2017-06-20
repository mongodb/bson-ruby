/*
 * Copyright (C) 2009-2013 MongoDB, Inc.
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

package org.rubybson;

import java.lang.management.ManagementFactory;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.Enumeration;
import java.util.Random;

/**
 * Encapsulates behaviour around finding a unique machine id for an object id.
 *
 * @since 2.0.0
 */
public class MachineId {

  /**
   * The value of the id.
   *
   * @since 2.0.0
   */
  private int value;

  /**
   * Instantiate the new machine id.
   *
   * @since 2.0.0
   */
  public MachineId() {
    this.value = generateMachineId() | generateProcessId();
  }

  /**
   * Get the integer value of the machine id.
   *
   * @return The integer for the machine id.
   *
   * @since 2.0.0
   */
  public int value() {
    return value;
  }

  /**
   * Generate the identifier for the machine.
   *
   * @return The machine id.
   *
   * @since 2.0.0
   */
  private int generateMachineId() {
    try {
      return networkInterfaces();
    }
    catch (SocketException error) {
      return new Random().nextInt() << 16;
    }
  }

  /**
   * Generate the identifier for the pid.
   *
   * @return The process id.
   *
   * @since 2.0.0
   */
  private int generateProcessId() {
    String processId = new String();
    int pid = ManagementFactory.getRuntimeMXBean().getName().hashCode();
    int loader = System.identityHashCode(MachineId.class.getClassLoader());
    processId += Integer.toHexString(pid);
    processId += Integer.toHexString(loader);
    return processId.hashCode() & 0xFFFF;
  }

  /**
   * Get the generated integer for all the known network interfaces of the machine.
   *
   * @return The network interfaces.
   *
   * @since 2.0.0
   */
  private int networkInterfaces() throws SocketException {
    String machineId = new String();
    Enumeration interfaces = NetworkInterface.getNetworkInterfaces();
    while (interfaces.hasMoreElements()) {
      machineId += interfaces.nextElement().toString();
    }
    return machineId.hashCode() & 0xFFFF;
  }
}
