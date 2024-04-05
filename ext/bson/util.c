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

#include "bson-native.h"

/**
 * Holds the machine id hash for object id generation.
 */
static char rb_bson_machine_id_hash[HOST_NAME_HASH_MAX];

/**
 * Holds a reference to the SecureRandom module, or Qnil if the modle is
 * not available.
 */
static VALUE pvt_SecureRandom = Qnil;

/**
 * Indicates whether or not the SecureRandom module responds to the
 * `random_number` method (depends on Ruby version).
 */
static int pvt_has_random_number = 0;

void rb_bson_generate_machine_id(VALUE rb_md5_class, char *rb_bson_machine_id)
{
  VALUE digest = rb_funcall(rb_md5_class, rb_intern("digest"), 1, rb_str_new2(rb_bson_machine_id));
  memcpy(rb_bson_machine_id_hash, RSTRING_PTR(digest), RSTRING_LEN(digest));
}

/**
 * Generate the next object id.
 *
 * Specification:
 * https://github.com/mongodb/specifications/blob/master/source/objectid.rst
 *
 * The ObjectID BSON type is a 12-byte value consisting of three different portions (fields):
 *   * a 4-byte value representing the seconds since the Unix epoch in the highest order bytes,
 *   * a 5-byte random number unique to a machine and process,
 *   * a 3-byte counter, starting with a random value.
 */
VALUE rb_bson_object_id_generator_next(int argc, VALUE* args, VALUE self)
{
  char bytes[12];
  uint32_t time_component;
  uint8_t* random_component;
  uint32_t counter_component;
  VALUE timestamp;
  VALUE rb_bson_object_id_class;

  rb_bson_object_id_class = pvt_const_get_2("BSON", "ObjectId");

  /* "Drivers SHOULD have an accessor method on an ObjectID class for
   * obtaining the timestamp value." */

  timestamp = rb_funcall(rb_bson_object_id_class, rb_intern("timestamp"), 0);
  time_component = BSON_UINT32_TO_BE(NUM2UINT(timestamp));

  /* "A 5-byte field consisting of a random value generated once per process.
   * This random value is unique to the machine and process.
   *
   * "Drivers MUST NOT have an accessor method on an ObjectID class for
   * obtaining this value."
   */

  random_component = pvt_get_object_id_random_value();

  /* shift left 8 bits, so that the first three bytes of the result are
   * the meaningful ones */
  counter_component = BSON_UINT32_TO_BE(rb_bson_object_id_counter << 8);

  memcpy(&bytes, &time_component, 4);
  memcpy(&bytes[4], random_component, 5);
  memcpy(&bytes[9], &counter_component, 3);

  rb_bson_object_id_counter = (rb_bson_object_id_counter + 1) % 0x1000000;

  return rb_str_new(bytes, 12);
}

/**
 * Reset the counter. This is purely as an aid for testing.
 *
 * @param [ Integer ] i the value to set the counter to (default is 0)
 */
VALUE rb_bson_object_id_generator_reset_counter(int argc, VALUE* args, VALUE self) {
  switch(argc) {
    case 0: rb_bson_object_id_counter = 0; break;
    case 1: rb_bson_object_id_counter = FIX2INT(args[0]); break;
    default: rb_raise(rb_eArgError, "Expected 0 or 1 arguments, got %d", argc);
  }

  return T_NIL;
}

/**
 * Returns a Ruby constant nested one level, e.g. BSON::Document.
 */
VALUE pvt_const_get_2(const char *c1, const char *c2) {
  return rb_const_get(rb_const_get(rb_cObject, rb_intern(c1)), rb_intern(c2));
}

/**
 * Returns a Ruby constant nested two levels, e.g. BSON::Regexp::Raw.
 */
VALUE pvt_const_get_3(const char *c1, const char *c2, const char *c3) {
  return rb_const_get(pvt_const_get_2(c1, c2), rb_intern(c3));
}

/**
 * Returns the value of the :mode option, or the default if the option is not
 * specified. Raises ArgumentError if the value is not one of nil or :bson.
 * A future version of bson-ruby is expected to also support :ruby and :ruby!
 * values. Returns one of the BSON_MODE_* values.
 */
int pvt_get_mode_option(int argc, VALUE *argv) {
  VALUE opts;
  VALUE mode;

  rb_scan_args(argc, argv, ":", &opts);
  if (NIL_P(opts)) {
    return BSON_MODE_DEFAULT;
  } else {
    mode = rb_hash_lookup(opts, ID2SYM(rb_intern("mode")));
    if (mode == Qnil) {
      return BSON_MODE_DEFAULT;
    } else if (mode == ID2SYM(rb_intern("bson"))) {
      return BSON_MODE_BSON;
    } else {
      rb_raise(rb_eArgError, "Invalid value for :mode option: %s",
        RSTRING_PTR(rb_funcall(mode, rb_intern("inspect"), 0)));
    }
  }
}

/**
 * Returns the random number associated with this host and process. If the
 * process ID changes (e.g. via fork), this will detect the change and
 * generate another random number.
 */
uint8_t* pvt_get_object_id_random_value() {
  static pid_t remembered_pid = 0;
  static uint8_t remembered_value[BSON_OBJECT_ID_RANDOM_VALUE_LENGTH] = {0};
  pid_t pid = getpid();

  if (remembered_pid != pid) {
    remembered_pid = pid;
    pvt_rand_buf(remembered_value, BSON_OBJECT_ID_RANDOM_VALUE_LENGTH, pid);
  }

  return remembered_value;
}

/**
 * Attempts to load the SecureRandom module
 */
VALUE pvt_load_secure_random(VALUE _arg) {
  rb_require("securerandom");
  pvt_SecureRandom = rb_const_get(rb_cObject, rb_intern("SecureRandom"));
  pvt_has_random_number = rb_respond_to(pvt_SecureRandom, rb_intern("random_number"));

  return Qnil;
}

/**
 * The fallback, if loading `securerandom` fails.
 */
VALUE pvt_rescue_load_secure_random(VALUE _arg, VALUE _exception) {
  pvt_SecureRandom = Qnil;

  return Qnil;
}

/**
 * Initializes the RNG.
 */
void pvt_init_rand() {
  // SecureRandom may fail to load because it's not present (LoadError), or
  // because it can't find a random device (NotImplementedError).
  rb_rescue2(pvt_load_secure_random, Qnil, pvt_rescue_load_secure_random, Qnil,
    rb_eLoadError, rb_eNotImpError, 0);
}

/**
 * Fills the buffer with random bytes. It prefers to use SecureRandom for
 * this, but in the very unlikely event that SecureRandom is not available,
 * it will fall back to a much-less-ideal generator using srand/rand.
 *
 * The `pid` argument is only used by the fallback, if SecureRandom is not
 * available.
 */
void pvt_rand_buf(uint8_t* bytes, int len, int pid) {
  if (pvt_SecureRandom != Qnil) {
    VALUE rb_bytes = rb_funcall(pvt_SecureRandom, rb_intern("bytes"), 1, INT2NUM(len));
    memcpy(bytes, StringValuePtr(rb_bytes), len);

  } else {
    time_t t;
    uint32_t seed;
    int ofs = 0;

    t = time(NULL);
    seed = ((uint32_t)t << 16) + ((uint32_t)pid % 0xFFFF);
    srand(seed);

    while (ofs < len) {
      int n = rand();
      unsigned remaining = len - ofs;

      if (remaining > sizeof(n)) remaining = sizeof(n);
      memcpy(bytes+ofs, &n, remaining);

      ofs += remaining;
    }
  }
}

/**
 * Returns a random integer between 0 and INT_MAX.
 */
int pvt_rand() {
  if (pvt_has_random_number) {
    VALUE result = rb_funcall(pvt_SecureRandom, rb_intern("random_number"), 1, INT2NUM(INT_MAX));
    return NUM2INT(result);

  } else if (pvt_SecureRandom != Qnil) {
    int result;
    VALUE rb_result = rb_funcall(pvt_SecureRandom, rb_intern("bytes"), 1, INT2NUM(sizeof(result)));
    memcpy(&result, StringValuePtr(rb_result), sizeof(result));
    return result;

  } else {
    srand((unsigned)time(NULL));
    return rand();
  }
}
