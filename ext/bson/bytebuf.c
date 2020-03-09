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
 * Allocates a bson byte buffer that wraps a byte_buffer_t.
 */
VALUE rb_bson_byte_buffer_allocate(VALUE klass)
{
  byte_buffer_t *b;
  VALUE obj = TypedData_Make_Struct(klass, byte_buffer_t, &rb_byte_buffer_data_type, b);
  b->b_ptr = b->buffer;
  b->size = BSON_BYTE_BUFFER_SIZE;
  return obj;
}

/**
 * Initialize a byte buffer.
 */
VALUE rb_bson_byte_buffer_initialize(int argc, VALUE *argv, VALUE self)
{
  VALUE bytes;
  rb_scan_args(argc, argv, "01", &bytes);

  if (!NIL_P(bytes)) {
    rb_bson_byte_buffer_put_bytes(self, bytes);
  }

  return self;
}

/**
 * Expand the byte buffer linearly.
 */
void rb_bson_expand_buffer(byte_buffer_t* buffer_ptr, size_t length)
{
  const size_t required_size = buffer_ptr->write_position - buffer_ptr->read_position + length;
  if (required_size <= buffer_ptr->size) {
    memmove(buffer_ptr->b_ptr, READ_PTR(buffer_ptr), READ_SIZE(buffer_ptr));
    buffer_ptr->write_position -= buffer_ptr->read_position;
    buffer_ptr->read_position = 0;
  } else {
    char *new_b_ptr;
    const size_t new_size = required_size * 2;
    new_b_ptr = ALLOC_N(char, new_size);
    memcpy(new_b_ptr, READ_PTR(buffer_ptr), READ_SIZE(buffer_ptr));
    if (buffer_ptr->b_ptr != buffer_ptr->buffer) {
      xfree(buffer_ptr->b_ptr);
    }
    buffer_ptr->b_ptr = new_b_ptr;
    buffer_ptr->size = new_size;
    buffer_ptr->write_position -= buffer_ptr->read_position;
    buffer_ptr->read_position = 0;
  }
}

/**
 * Free the memory for the byte buffer.
 */
void rb_bson_byte_buffer_free(void *ptr)
{
  byte_buffer_t *b = ptr;
  if (b->b_ptr != b->buffer) {
    xfree(b->b_ptr);
  }
  xfree(b);
}

/**
 * Get the length of the buffer.
 */
VALUE rb_bson_byte_buffer_length(VALUE self)
{
  byte_buffer_t *b;
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  return UINT2NUM(READ_SIZE(b));
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_read_position(VALUE self)
{
  byte_buffer_t *b;
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  return INT2NUM(b->read_position);
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_rewind(VALUE self)
{
  byte_buffer_t *b;
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  b->read_position = 0;

  return self;
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_write_position(VALUE self)
{
  byte_buffer_t *b;
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  return INT2NUM(b->write_position);
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_to_s(VALUE self)
{
  byte_buffer_t *b;
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  return rb_str_new(READ_PTR(b), READ_SIZE(b));
}

/**
 * Get the size of the byte_buffer_t in memory.
 */
size_t rb_bson_byte_buffer_memsize(const void *ptr)
{
  return ptr ? sizeof(byte_buffer_t) : 0;
}
