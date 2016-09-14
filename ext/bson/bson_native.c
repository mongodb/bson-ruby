/*
 * Copyright (C) 2009-2016 MongoDB Inc.
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
#include <ruby/encoding.h>
#include <stdbool.h>
#include <time.h>
#include <unistd.h>
#include "native-endian.h"

#define BSON_BYTE_BUFFER_SIZE 1024

#ifndef HOST_NAME_HASH_MAX
#define HOST_NAME_HASH_MAX 256
#endif

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

#define ENSURE_BSON_READ(buffer_ptr, length) \
  { if (buffer_ptr->read_position + length > buffer_ptr->write_position) \
    rb_raise(rb_eRangeError, "Attempted to read %zu bytes, but only %zu bytes remain", (size_t)length, READ_SIZE(buffer_ptr)); }

static VALUE rb_bson_byte_buffer_allocate(VALUE klass);
static VALUE rb_bson_byte_buffer_initialize(int argc, VALUE *argv, VALUE self);
static VALUE rb_bson_byte_buffer_length(VALUE self);
static VALUE rb_bson_byte_buffer_get_byte(VALUE self);
static VALUE rb_bson_byte_buffer_get_bytes(VALUE self, VALUE i);
static VALUE rb_bson_byte_buffer_get_cstring(VALUE self);
static VALUE rb_bson_byte_buffer_get_decimal128_bytes(VALUE self);
static VALUE rb_bson_byte_buffer_get_double(VALUE self);
static VALUE rb_bson_byte_buffer_get_int32(VALUE self);
static VALUE rb_bson_byte_buffer_get_int64(VALUE self);
static VALUE rb_bson_byte_buffer_get_string(VALUE self);
static VALUE rb_bson_byte_buffer_put_byte(VALUE self, VALUE byte);
static VALUE rb_bson_byte_buffer_put_bytes(VALUE self, VALUE bytes);
static VALUE rb_bson_byte_buffer_put_cstring(VALUE self, VALUE string);
static VALUE rb_bson_byte_buffer_put_decimal128(VALUE self, VALUE low, VALUE high);
static VALUE rb_bson_byte_buffer_put_double(VALUE self, VALUE f);
static VALUE rb_bson_byte_buffer_put_int32(VALUE self, VALUE i);
static VALUE rb_bson_byte_buffer_put_int64(VALUE self, VALUE i);
static VALUE rb_bson_byte_buffer_put_string(VALUE self, VALUE string);
static VALUE rb_bson_byte_buffer_read_position(VALUE self);
static VALUE rb_bson_byte_buffer_replace_int32(VALUE self, VALUE index, VALUE i);
static VALUE rb_bson_byte_buffer_rewind(VALUE self);
static VALUE rb_bson_byte_buffer_write_position(VALUE self);
static VALUE rb_bson_byte_buffer_to_s(VALUE self);
static VALUE rb_bson_object_id_generator_next(int argc, VALUE* args, VALUE self);

static size_t rb_bson_byte_buffer_memsize(const void *ptr);
static void rb_bson_byte_buffer_free(void *ptr);
static void rb_bson_expand_buffer(byte_buffer_t* buffer_ptr, size_t length);
static void rb_bson_generate_machine_id(VALUE rb_md5_class, char *rb_bson_machine_id);
static bool rb_bson_utf8_validate(const char *utf8, size_t utf8_len, bool allow_null);

static const rb_data_type_t rb_byte_buffer_data_type = {
  "bson/byte_buffer",
  { NULL, rb_bson_byte_buffer_free, rb_bson_byte_buffer_memsize }
};

/**
 * Holds the machine id hash for object id generation.
 */
static char rb_bson_machine_id_hash[HOST_NAME_HASH_MAX];

/**
 * The counter for incrementing object ids.
 */
static uint32_t rb_bson_object_id_counter;

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

  rb_define_alloc_func(rb_byte_buffer_class, rb_bson_byte_buffer_allocate);
  rb_define_method(rb_byte_buffer_class, "initialize", rb_bson_byte_buffer_initialize, -1);
  rb_define_method(rb_byte_buffer_class, "length", rb_bson_byte_buffer_length, 0);
  rb_define_method(rb_byte_buffer_class, "get_byte", rb_bson_byte_buffer_get_byte, 0);
  rb_define_method(rb_byte_buffer_class, "get_bytes", rb_bson_byte_buffer_get_bytes, 1);
  rb_define_method(rb_byte_buffer_class, "get_cstring", rb_bson_byte_buffer_get_cstring, 0);
  rb_define_method(rb_byte_buffer_class, "get_decimal128_bytes", rb_bson_byte_buffer_get_decimal128_bytes, 0);
  rb_define_method(rb_byte_buffer_class, "get_double", rb_bson_byte_buffer_get_double, 0);
  rb_define_method(rb_byte_buffer_class, "get_int32", rb_bson_byte_buffer_get_int32, 0);
  rb_define_method(rb_byte_buffer_class, "get_int64", rb_bson_byte_buffer_get_int64, 0);
  rb_define_method(rb_byte_buffer_class, "get_string", rb_bson_byte_buffer_get_string, 0);
  rb_define_method(rb_byte_buffer_class, "put_byte", rb_bson_byte_buffer_put_byte, 1);
  rb_define_method(rb_byte_buffer_class, "put_bytes", rb_bson_byte_buffer_put_bytes, 1);
  rb_define_method(rb_byte_buffer_class, "put_cstring", rb_bson_byte_buffer_put_cstring, 1);
  rb_define_method(rb_byte_buffer_class, "put_decimal128", rb_bson_byte_buffer_put_decimal128, 2);
  rb_define_method(rb_byte_buffer_class, "put_double", rb_bson_byte_buffer_put_double, 1);
  rb_define_method(rb_byte_buffer_class, "put_int32", rb_bson_byte_buffer_put_int32, 1);
  rb_define_method(rb_byte_buffer_class, "put_int64", rb_bson_byte_buffer_put_int64, 1);
  rb_define_method(rb_byte_buffer_class, "put_string", rb_bson_byte_buffer_put_string, 1);
  rb_define_method(rb_byte_buffer_class, "read_position", rb_bson_byte_buffer_read_position, 0);
  rb_define_method(rb_byte_buffer_class, "replace_int32", rb_bson_byte_buffer_replace_int32, 2);
  rb_define_method(rb_byte_buffer_class, "rewind!", rb_bson_byte_buffer_rewind, 0);
  rb_define_method(rb_byte_buffer_class, "write_position", rb_bson_byte_buffer_write_position, 0);
  rb_define_method(rb_byte_buffer_class, "to_s", rb_bson_byte_buffer_to_s, 0);
  rb_define_method(rb_bson_object_id_generator_class, "next_object_id", rb_bson_object_id_generator_next, -1);

  // Get the object id machine id and hash it.
  rb_require("digest/md5");
  gethostname(rb_bson_machine_id, sizeof(rb_bson_machine_id));
  rb_bson_machine_id[255] = '\0';
  rb_bson_generate_machine_id(rb_md5_class, rb_bson_machine_id);

  // Set the object id counter to a random number
  rb_bson_object_id_counter = FIX2INT(rb_funcall(rb_mKernel, rb_intern("rand"), 1, INT2FIX(0x1000000)));
}

void rb_bson_generate_machine_id(VALUE rb_md5_class, char *rb_bson_machine_id)
{
  VALUE digest = rb_funcall(rb_md5_class, rb_intern("digest"), 1, rb_str_new2(rb_bson_machine_id));
  memcpy(rb_bson_machine_id_hash, RSTRING_PTR(digest), RSTRING_LEN(digest));
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
 * Get the length of the buffer.
 */
VALUE rb_bson_byte_buffer_length(VALUE self)
{
  byte_buffer_t *b;
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  return UINT2NUM(READ_SIZE(b));
}

/**
 * Get a single byte from the buffer.
 */
VALUE rb_bson_byte_buffer_get_byte(VALUE self)
{
  byte_buffer_t *b;
  VALUE byte;

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_READ(b, 1);
  byte = rb_str_new(READ_PTR(b), 1);
  b->read_position += 1;
  return byte;
}

/**
 * Get bytes from the buffer.
 */
VALUE rb_bson_byte_buffer_get_bytes(VALUE self, VALUE i)
{
  byte_buffer_t *b;
  VALUE bytes;
  const uint32_t length = FIX2LONG(i);

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_READ(b, length);
  bytes = rb_str_new(READ_PTR(b), length);
  b->read_position += length;
  return bytes;
}

/**
 * Get a cstring from the buffer.
 */
VALUE rb_bson_byte_buffer_get_cstring(VALUE self)
{
  byte_buffer_t *b;
  VALUE string;
  int length;

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  length = (int)strlen(READ_PTR(b));
  ENSURE_BSON_READ(b, length);
  string = rb_enc_str_new(READ_PTR(b), length, rb_utf8_encoding());
  b->read_position += length + 1;
  return string;
}

/**
 * Get the 16 bytes representing the decimal128 from the buffer.
 */
VALUE rb_bson_byte_buffer_get_decimal128_bytes(VALUE self)
{
  byte_buffer_t *b;
  VALUE bytes;

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_READ(b, 16);
  bytes = rb_str_new(READ_PTR(b), 16);
  b->read_position += 16;
  return bytes;
}

/**
 * Get a double from the buffer.
 */
VALUE rb_bson_byte_buffer_get_double(VALUE self)
{
  byte_buffer_t *b;
  double d;

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_READ(b, 8);
  memcpy(&d, READ_PTR(b), 8);
  b->read_position += 8;
  return DBL2NUM(BSON_DOUBLE_FROM_LE(d));
}

/**
 * Get a int32 from the buffer.
 */
VALUE rb_bson_byte_buffer_get_int32(VALUE self)
{
  byte_buffer_t *b;
  int32_t i32;

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_READ(b, 4);
  memcpy(&i32, READ_PTR(b), 4);
  b->read_position += 4;
  return INT2NUM(BSON_UINT32_FROM_LE(i32));
}

/**
 * Get a int64 from the buffer.
 */
VALUE rb_bson_byte_buffer_get_int64(VALUE self)
{
  byte_buffer_t *b;
  int64_t i64;

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_READ(b, 8);
  memcpy(&i64, READ_PTR(b), 8);
  b->read_position += 8;
  return LL2NUM(BSON_UINT64_FROM_LE(i64));
}

/**
 * Get a string from the buffer.
 */
VALUE rb_bson_byte_buffer_get_string(VALUE self)
{
  byte_buffer_t *b;
  int32_t length;
  int32_t length_le;
  VALUE string;

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_READ(b, 4);
  memcpy(&length, READ_PTR(b), 4);
  length_le = BSON_UINT32_FROM_LE(length);
  b->read_position += 4;
  ENSURE_BSON_READ(b, length_le);
  string = rb_enc_str_new(READ_PTR(b), length_le - 1, rb_utf8_encoding());
  b->read_position += length_le;
  return string;
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
  char *c_str = RSTRING_PTR(string);
  size_t length = RSTRING_LEN(string) + 1;

  if (!rb_bson_utf8_validate(c_str, length - 1, false)) {
    rb_raise(rb_eArgError, "String %s is not a valid UTF-8 CString.", c_str);
  }

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, length);
  memcpy(WRITE_PTR(b), c_str, length);
  b->write_position += length;
  return self;
}

/**
 * Writes a 128 bit decimal to the byte buffer.
 */
VALUE rb_bson_byte_buffer_put_decimal128(VALUE self, VALUE low, VALUE high)
{
  byte_buffer_t *b;
  const int64_t low64 = BSON_UINT64_TO_LE(NUM2ULL(low));
  const int64_t high64 = BSON_UINT64_TO_LE(NUM2ULL(high));

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, 8);
  memcpy(WRITE_PTR(b), &low64, 8);
  b->write_position += 8;

  ENSURE_BSON_WRITE(b, 8);
  memcpy(WRITE_PTR(b), &high64, 8);
  b->write_position += 8;

  return self;
}

/**
 * Writes a 64 bit double to the buffer.
 */
VALUE rb_bson_byte_buffer_put_double(VALUE self, VALUE f)
{
  byte_buffer_t *b;
  const double d = BSON_DOUBLE_TO_LE(NUM2DBL(f));
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, 8);
  memcpy(WRITE_PTR(b), &d, 8);
  b->write_position += 8;

  return self;
}

/**
 * Writes a 32 bit integer to the byte buffer.
 */
VALUE rb_bson_byte_buffer_put_int32(VALUE self, VALUE i)
{
  byte_buffer_t *b;
  const int32_t i32 = BSON_UINT32_TO_LE(NUM2INT(i));

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, 4);
  memcpy(WRITE_PTR(b), &i32, 4);
  b->write_position += 4;

  return self;
}

/**
 * Writes a 64 bit integer to the byte buffer.
 */
VALUE rb_bson_byte_buffer_put_int64(VALUE self, VALUE i)
{
  byte_buffer_t *b;
  const int64_t i64 = BSON_UINT64_TO_LE(NUM2LL(i));

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, 8);
  memcpy(WRITE_PTR(b), &i64, 8);
  b->write_position += 8;

  return self;
}

/**
 * Writes a string to the byte buffer.
 */
VALUE rb_bson_byte_buffer_put_string(VALUE self, VALUE string)
{
  byte_buffer_t *b;
  int32_t length_le;

  char *str = RSTRING_PTR(string);
  const int32_t length = RSTRING_LEN(string) + 1;
  length_le = BSON_UINT32_TO_LE(length);

  if (!rb_bson_utf8_validate(str, length - 1, true)) {
    rb_raise(rb_eArgError, "String %s is not valid UTF-8.", str);
  }

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, length + 4);
  memcpy(WRITE_PTR(b), &length_le, 4);
  b->write_position += 4;
  memcpy(WRITE_PTR(b), str, length);
  b->write_position += length;

  return self;
}

/**
 * Get the read position.
 */
VALUE rb_bson_byte_buffer_read_position(VALUE self)
{
  byte_buffer_t *b;
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  return INT2NUM(b->read_position);
}

/**
 * Replace a 32 bit integer int the byte buffer.
 */
VALUE rb_bson_byte_buffer_replace_int32(VALUE self, VALUE index, VALUE i)
{
  byte_buffer_t *b;
  const int32_t position = NUM2LONG(index);
  const int32_t i32 = BSON_UINT32_TO_LE(NUM2LONG(i));

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);

  memcpy(READ_PTR(b) + position, &i32, 4);

  return self;
}

/**
 * Reset the read position to the beginning of the byte buffer.
 */
VALUE rb_bson_byte_buffer_rewind(VALUE self)
{
  byte_buffer_t *b;
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  b->read_position = 0;

  return self;
}

/**
 * Get the write position.
 */
VALUE rb_bson_byte_buffer_write_position(VALUE self)
{
  byte_buffer_t *b;
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  return INT2NUM(b->write_position);
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
  if (b->b_ptr != b->buffer) {
    xfree(b->b_ptr);
  }
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
 * Taken from libbson.
 */
static void _bson_utf8_get_sequence(const char *utf8, uint8_t *seq_length, uint8_t *first_mask)
{
 unsigned char c = *(const unsigned char *)utf8;
 uint8_t m;
 uint8_t n;

 /*
  * See the following[1] for a description of what the given multi-byte
  * sequences will be based on the bits set of the first byte. We also need
  * to mask the first byte based on that.  All subsequent bytes are masked
  * against 0x3F.
  *
  * [1] http://www.joelonsoftware.com/articles/Unicode.html
  */

 if ((c & 0x80) == 0) {
  n = 1;
  m = 0x7F;
 } else if ((c & 0xE0) == 0xC0) {
  n = 2;
  m = 0x1F;
 } else if ((c & 0xF0) == 0xE0) {
  n = 3;
  m = 0x0F;
 } else if ((c & 0xF8) == 0xF0) {
  n = 4;
  m = 0x07;
 } else if ((c & 0xFC) == 0xF8) {
  n = 5;
  m = 0x03;
 } else if ((c & 0xFE) == 0xFC) {
  n = 6;
  m = 0x01;
 } else {
  n = 0;
  m = 0;
 }

 *seq_length = n;
 *first_mask = m;
}

/**
 * Taken from libbson.
 */
bool rb_bson_utf8_validate(const char *utf8, size_t utf8_len, bool allow_null)
{
  uint32_t c;
  uint8_t first_mask;
  uint8_t seq_length;
  unsigned i;
  unsigned j;

  if (!utf8) {
    return false;
  }

  for (i = 0; i < utf8_len; i += seq_length) {
    _bson_utf8_get_sequence(&utf8[i], &seq_length, &first_mask);

    /*
     * Ensure we have a valid multi-byte sequence length.
     */
    if (!seq_length) {
      return false;
    }

    /*
     * Ensure we have enough bytes left.
     */
    if ((utf8_len - i) < seq_length) {
      return false;
    }

    /*
     * Also calculate the next char as a unichar so we can
     * check code ranges for non-shortest form.
     */
    c = utf8 [i] & first_mask;

    /*
     * Check the high-bits for each additional sequence byte.
     */
    for (j = i + 1; j < (i + seq_length); j++) {
      c = (c << 6) | (utf8 [j] & 0x3F);
      if ((utf8[j] & 0xC0) != 0x80) {
        return false;
      }
    }

    /*
     * Check for NULL bytes afterwards.
     *
     * Hint: if you want to optimize this function, starting here to do
     * this in the same pass as the data above would probably be a good
     * idea. You would add a branch into the inner loop, but save possibly
     * on cache-line bouncing on larger strings. Just a thought.
     */
    if (!allow_null) {
      for (j = 0; j < seq_length; j++) {
        if (((i + j) > utf8_len) || !utf8[i + j]) {
          return false;
        }
      }
    }

    /*
     * Code point wont fit in utf-16, not allowed.
     */
    if (c > 0x0010FFFF) {
      return false;
    }

    /*
     * Byte is in reserved range for UTF-16 high-marks
     * for surrogate pairs.
     */
    if ((c & 0xFFFFF800) == 0xD800) {
      return false;
    }

    /*
     * Check non-shortest form unicode.
     */
    switch (seq_length) {
    case 1:
      if (c <= 0x007F) {
        continue;
      }
      return false;

    case 2:
      if ((c >= 0x0080) && (c <= 0x07FF)) {
        continue;
      } else if (c == 0) {
        /* Two-byte representation for NULL. */
        continue;
      }
      return false;

    case 3:
      if (((c >= 0x0800) && (c <= 0x0FFF)) ||
         ((c >= 0x1000) && (c <= 0xFFFF))) {
        continue;
      }
      return false;

    case 4:
      if (((c >= 0x10000) && (c <= 0x3FFFF)) ||
         ((c >= 0x40000) && (c <= 0xFFFFF)) ||
         ((c >= 0x100000) && (c <= 0x10FFFF))) {
        continue;
      }
      return false;

    default:
      return false;
    }
  }

  return true;
}
