/*
 * Copyright (C) 2009-2013 MongoDB Inc.
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
#include <ruby.h>
#include <bson.h>

static VALUE rb_bson_byte_buffer_allocate(VALUE klass);

static size_t rb_bson_byte_buffer_memsize(const void *ptr);

static const rb_data_type_t rb_bson_data_type = {
    "bson/byte_buffer",
    { NULL, RUBY_DEFAULT_FREE, rb_bson_byte_buffer_memsize }
};

void Init_native()
{
  VALUE bson_module        = rb_define_module("BSON");
  VALUE byte_buffer_class  = rb_define_class_under(bson_module, "ByteBuffer", rb_cObject);

  rb_define_alloc_func(byte_buffer_class, rb_bson_byte_buffer_allocate);
}

/**
 * Allocates a bson byte buffer that wraps a bson_t into memory.
 */
VALUE rb_bson_byte_buffer_allocate(VALUE klass)
{
  bson_t *bson;
  VALUE obj = TypedData_Make_Struct(klass, bson_t, &rb_bson_data_type, bson);
  return obj;
}

/**
 * Get the size of the bson_t in memory.
 */
size_t rb_bson_byte_buffer_memsize(const void *ptr)
{
  return ptr ? sizeof(bson_t) : 0;
}
