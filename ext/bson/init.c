/*
 * Copyright (C) 2009-2019 MongoDB Inc.
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
 * The counter for incrementing object ids.
 */
uint32_t rb_bson_object_id_counter;


VALUE rb_bson_registry;

VALUE rb_bson_illegal_key;

const rb_data_type_t rb_byte_buffer_data_type = {
  "bson/byte_buffer",
  { NULL, rb_bson_byte_buffer_free, rb_bson_byte_buffer_memsize }
};

/**
 * Initialize the bson_native extension.
 */
void Init_bson_native()
{
  char rb_bson_machine_id[256];

  VALUE rb_bson_module = rb_define_module("BSON");
  VALUE rb_byte_buffer_class = rb_define_class_under(rb_bson_module, "ByteBuffer", rb_cObject);
  VALUE rb_bson_object_id_class = rb_const_get(rb_bson_module, rb_intern("ObjectId"));
  VALUE rb_bson_object_id_generator_class = rb_const_get(rb_bson_object_id_class, rb_intern("Generator"));
  VALUE rb_digest_class = rb_const_get(rb_cObject, rb_intern("Digest"));
  VALUE rb_md5_class = rb_const_get(rb_digest_class, rb_intern("MD5"));

  rb_bson_illegal_key = rb_const_get(rb_const_get(rb_bson_module, rb_intern("String")),rb_intern("IllegalKey"));

  rb_define_alloc_func(rb_byte_buffer_class, rb_bson_byte_buffer_allocate);
  rb_define_method(rb_byte_buffer_class, "initialize", rb_bson_byte_buffer_initialize, -1);
  rb_define_method(rb_byte_buffer_class, "length", rb_bson_byte_buffer_length, 0);
  
  rb_define_method(rb_byte_buffer_class, "read_position", rb_bson_byte_buffer_read_position, 0);
  rb_define_method(rb_byte_buffer_class, "get_byte", rb_bson_byte_buffer_get_byte, 0);
  rb_define_method(rb_byte_buffer_class, "get_bytes", rb_bson_byte_buffer_get_bytes, 1);
  rb_define_method(rb_byte_buffer_class, "get_cstring", rb_bson_byte_buffer_get_cstring, 0);
  rb_define_method(rb_byte_buffer_class, "get_decimal128_bytes", rb_bson_byte_buffer_get_decimal128_bytes, 0);
  rb_define_method(rb_byte_buffer_class, "get_double", rb_bson_byte_buffer_get_double, 0);
  rb_define_method(rb_byte_buffer_class, "get_hash", rb_bson_byte_buffer_get_hash, 0);
  rb_define_method(rb_byte_buffer_class, "get_array", rb_bson_byte_buffer_get_array, 0);
  rb_define_method(rb_byte_buffer_class, "get_int32", rb_bson_byte_buffer_get_int32, 0);
  rb_define_method(rb_byte_buffer_class, "get_int64", rb_bson_byte_buffer_get_int64, 0);
  rb_define_method(rb_byte_buffer_class, "get_string", rb_bson_byte_buffer_get_string, 0);
  
  rb_define_method(rb_byte_buffer_class, "write_position", rb_bson_byte_buffer_write_position, 0);
  rb_define_method(rb_byte_buffer_class, "put_byte", rb_bson_byte_buffer_put_byte, 1);
  rb_define_method(rb_byte_buffer_class, "put_bytes", rb_bson_byte_buffer_put_bytes, 1);
  rb_define_method(rb_byte_buffer_class, "put_cstring", rb_bson_byte_buffer_put_cstring, 1);
  rb_define_method(rb_byte_buffer_class, "put_decimal128", rb_bson_byte_buffer_put_decimal128, 2);
  rb_define_method(rb_byte_buffer_class, "put_double", rb_bson_byte_buffer_put_double, 1);
  rb_define_method(rb_byte_buffer_class, "put_int32", rb_bson_byte_buffer_put_int32, 1);
  rb_define_method(rb_byte_buffer_class, "put_int64", rb_bson_byte_buffer_put_int64, 1);
  rb_define_method(rb_byte_buffer_class, "put_string", rb_bson_byte_buffer_put_string, 1);
  rb_define_method(rb_byte_buffer_class, "put_symbol", rb_bson_byte_buffer_put_symbol, 1);
  rb_define_method(rb_byte_buffer_class, "put_hash", rb_bson_byte_buffer_put_hash, 2);
  rb_define_method(rb_byte_buffer_class, "put_array", rb_bson_byte_buffer_put_array, 2);
  
  rb_define_method(rb_byte_buffer_class, "replace_int32", rb_bson_byte_buffer_replace_int32, 2);
  rb_define_method(rb_byte_buffer_class, "rewind!", rb_bson_byte_buffer_rewind, 0);
  rb_define_method(rb_byte_buffer_class, "to_s", rb_bson_byte_buffer_to_s, 0);
  rb_define_method(rb_bson_object_id_generator_class, "next_object_id", rb_bson_object_id_generator_next, -1);

  // Get the object id machine id and hash it.
  rb_require("digest/md5");
  gethostname(rb_bson_machine_id, sizeof(rb_bson_machine_id));
  rb_bson_machine_id[255] = '\0';
  rb_bson_generate_machine_id(rb_md5_class, rb_bson_machine_id);

  // Set the object id counter to a random number
  rb_bson_object_id_counter = FIX2INT(rb_funcall(rb_mKernel, rb_intern("rand"), 1, INT2FIX(0x1000000)));

  rb_bson_registry = rb_const_get(rb_bson_module, rb_intern("Registry"));
}
