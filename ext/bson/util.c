/*
 * Copyright (C) 2009-2019 MongoDB, Inc.
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
