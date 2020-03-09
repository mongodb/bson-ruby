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

void rb_bson_generate_machine_id(VALUE rb_md5_class, char *rb_bson_machine_id)
{
  VALUE digest = rb_funcall(rb_md5_class, rb_intern("digest"), 1, rb_str_new2(rb_bson_machine_id));
  memcpy(rb_bson_machine_id_hash, RSTRING_PTR(digest), RSTRING_LEN(digest));
}

/**
 * Generate the next object id.
 */
VALUE rb_bson_object_id_generator_next(int argc, VALUE* args, VALUE self)
{
  char bytes[12];
  uint32_t t;
  uint32_t c;
  uint16_t pid = BSON_UINT16_TO_BE(getpid());

  if (argc == 0 || (argc == 1 && *args == Qnil)) {
    t = BSON_UINT32_TO_BE((int) time(NULL));
  }
  else {
    t = BSON_UINT32_TO_BE(NUM2ULONG(rb_funcall(*args, rb_intern("to_i"), 0)));
  }

  c = BSON_UINT32_TO_BE(rb_bson_object_id_counter << 8);

  memcpy(&bytes, &t, 4);
  memcpy(&bytes[4], rb_bson_machine_id_hash, 3);
  memcpy(&bytes[7], &pid, 2);
  memcpy(&bytes[9], &c, 3);
  rb_bson_object_id_counter++;
  return rb_str_new(bytes, 12);
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
