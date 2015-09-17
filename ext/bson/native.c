/*
 * Copyright (C) 2009-2015 MongoDB Inc.
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
#include "portable_endian.h"

#define BSON_BYTE_BUFFER_SIZE 512

typedef struct {
  size_t size;
  size_t write_position;
  size_t read_position;
  char   buffer[BSON_BYTE_BUFFER_SIZE];
  char   *b_ptr;
} byte_buffer_t;

#define READ_PTR(byte_buffer_ptr) \
  (byte_buffer_ptr->b_ptr + byte_buffer_ptr->read_position)

#define READ_SIZE(byte_buffer_ptr) \
  (byte_buffer_ptr->write_position - byte_buffer_ptr->read_position)

#define WRITE_PTR(byte_buffer_ptr) \
  (byte_buffer_ptr->b_ptr + byte_buffer_ptr->write_position)

#define ENSURE_BSON_WRITE(buffer_ptr, length) \
  { if (buffer_ptr->write_position + length > buffer_ptr->size) rb_bson_expand_buffer(buffer_ptr, length); }

static VALUE rb_bson_byte_buffer_allocate(VALUE klass);
static VALUE rb_bson_byte_buffer_length(VALUE self);
static VALUE rb_bson_byte_buffer_put_byte(VALUE self, VALUE byte);
static VALUE rb_bson_byte_buffer_put_bytes(VALUE self, VALUE bytes);
static VALUE rb_bson_byte_buffer_put_cstring(VALUE self, VALUE string);
static VALUE rb_bson_byte_buffer_put_double(VALUE self, VALUE f);
static VALUE rb_bson_byte_buffer_put_int32(VALUE self, VALUE i);
static VALUE rb_bson_byte_buffer_put_int64(VALUE self, VALUE i);
static VALUE rb_bson_byte_buffer_put_string(VALUE self, VALUE string);
static VALUE rb_bson_byte_buffer_replace_int32(VALUE self, VALUE index, VALUE i);
static VALUE rb_bson_byte_buffer_to_s(VALUE self);

static size_t rb_bson_byte_buffer_memsize(const void *ptr);
static void rb_bson_byte_buffer_free(void *ptr);
static void rb_bson_expand_buffer(byte_buffer_t* buffer_ptr, size_t length);

static const rb_data_type_t rb_byte_buffer_data_type = {
  "bson/byte_buffer",
  { NULL, rb_bson_byte_buffer_free, rb_bson_byte_buffer_memsize }
};

/**
 * Initialize the native extension.
 */
void Init_native()
{
  VALUE rb_bson_module = rb_define_module("BSON");
  VALUE rb_byte_buffer_class = rb_define_class_under(rb_bson_module, "ByteBuffer", rb_cObject);

  rb_define_alloc_func(rb_byte_buffer_class, rb_bson_byte_buffer_allocate);
  rb_define_method(rb_byte_buffer_class, "length", rb_bson_byte_buffer_length, 0);
  rb_define_method(rb_byte_buffer_class, "put_byte", rb_bson_byte_buffer_put_byte, 1);
  rb_define_method(rb_byte_buffer_class, "put_bytes", rb_bson_byte_buffer_put_bytes, 1);
  rb_define_method(rb_byte_buffer_class, "put_cstring", rb_bson_byte_buffer_put_cstring, 1);
  rb_define_method(rb_byte_buffer_class, "put_double", rb_bson_byte_buffer_put_double, 1);
  rb_define_method(rb_byte_buffer_class, "put_int32", rb_bson_byte_buffer_put_int32, 1);
  rb_define_method(rb_byte_buffer_class, "put_int64", rb_bson_byte_buffer_put_int64, 1);
  rb_define_method(rb_byte_buffer_class, "put_string", rb_bson_byte_buffer_put_string, 1);
  rb_define_method(rb_byte_buffer_class, "replace_int32", rb_bson_byte_buffer_replace_int32, 2);
  rb_define_method(rb_byte_buffer_class, "to_s", rb_bson_byte_buffer_to_s, 0);
}

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
 * Get the length of the buffer.
 */
VALUE rb_bson_byte_buffer_length(VALUE self)
{
  byte_buffer_t *b;
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  return UINT2NUM(READ_SIZE(b));
}

/**
 * Writes a byte to the byte buffer.
 */
VALUE rb_bson_byte_buffer_put_byte(VALUE self, VALUE byte)
{
  byte_buffer_t *b;
  const char *str = RSTRING_PTR(byte);

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, 1);
  memcpy(WRITE_PTR(b), str, 1);
  b->write_position += 1;

  return self;
}

/**
 * Writes bytes to the byte buffer.
 */
VALUE rb_bson_byte_buffer_put_bytes(VALUE self, VALUE bytes)
{
  byte_buffer_t *b;
  const char *str = RSTRING_PTR(bytes);
  const size_t length = RSTRING_LEN(bytes);

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, length);
  memcpy(WRITE_PTR(b), str, length);
  b->write_position += length;

  return self;
}

/**
 * Writes a cstring to the byte buffer.
 */
VALUE rb_bson_byte_buffer_put_cstring(VALUE self, VALUE string)
{
  byte_buffer_t *b;
  const char *c_str = RSTRING_PTR(string);
  const size_t length = RSTRING_LEN(string) + 1;
  if (strlen(c_str) < length - 1)
    rb_raise(rb_eArgError, "Illegal C-String %s contains a null byte.", c_str);

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, length);
  memcpy(WRITE_PTR(b), c_str, length);
  b->write_position += length;

  return self;
}

/**
 * Writes a 64 bit double to the buffer.
 */
VALUE rb_bson_byte_buffer_put_double(VALUE self, VALUE f)
{
  byte_buffer_t *b;
  union {double d; uint64_t i64;} ucast;

  ucast.d = NUM2DBL(f);
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, 8);
  ucast.i64 = htole64(ucast.i64);
  *(int64_t*)WRITE_PTR(b) = ucast.i64;
  b->write_position += 8;

  return self;
}

/**
 * Writes a 32 bit integer to the byte buffer.
 */
VALUE rb_bson_byte_buffer_put_int32(VALUE self, VALUE i)
{
  byte_buffer_t *b;
  const int32_t i32 = NUM2INT(i);

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, 4);
  *((int32_t*)WRITE_PTR(b)) = htole32(i32);
  b->write_position += 4;

  return self;
}

/**
 * Writes a 64 bit integer to the byte buffer.
 */
VALUE rb_bson_byte_buffer_put_int64(VALUE self, VALUE i)
{
  byte_buffer_t *b;
  const int64_t i64 = NUM2LONG(i);

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, 8);
  *((int64_t*)WRITE_PTR(b)) = htole64(i64);
  b->write_position += 8;

  return self;
}

/**
 * Writes a string to the byte buffer.
 */
VALUE rb_bson_byte_buffer_put_string(VALUE self, VALUE string)
{
  byte_buffer_t *b;
  const char *str = RSTRING_PTR(string);
  const size_t length = RSTRING_LEN(string) + 1;

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, length + 4);
  *((int32_t*)WRITE_PTR(b)) = htole32(length);
  b->write_position += 4;
  memcpy(WRITE_PTR(b), str, length);
  b->write_position += length;

  return self;
}

/**
 * Replace a 32 bit integer int the byte buffer.
 */
VALUE rb_bson_byte_buffer_replace_int32(VALUE self, VALUE index, VALUE i)
{
  byte_buffer_t *b;
  const int32_t position = NUM2INT(index);
  const int32_t i32 = NUM2INT(i);
  const char bytes = htole32(i32);

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);

  memcpy(READ_PTR(b) + position, &bytes, sizeof(bytes));

  return self;
}

/**
 * Convert the buffer to a string.
 */
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

/**
 * Free the memory for the byte buffer.
 */
void rb_bson_byte_buffer_free(void *ptr)
{
  byte_buffer_t *b = ptr;
  if (b->b_ptr != b->buffer) xfree(b->b_ptr);
  xfree(b);
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
    const size_t new_size = buffer_ptr->size + BSON_BYTE_BUFFER_SIZE;
    new_b_ptr = ALLOC_N(char, new_size);
    memcpy(new_b_ptr, READ_PTR(buffer_ptr), READ_SIZE(buffer_ptr));
    if (buffer_ptr->b_ptr != buffer_ptr->buffer) xfree(buffer_ptr->b_ptr);
    buffer_ptr->b_ptr = new_b_ptr;
    buffer_ptr->size = new_size;
    buffer_ptr->write_position -= buffer_ptr->read_position;
    buffer_ptr->read_position = 0;
  }
}
