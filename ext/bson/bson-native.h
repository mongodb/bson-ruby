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

#include <ruby.h>
#include <stdbool.h>
#include <stdint.h>
#include <unistd.h>
#include <time.h>
#include "bson-endian.h"

void
rb_bson_utf8_validate (const char *utf8, /* IN */
                    size_t utf8_len,  /* IN */
                    bool allow_null, /* IN */
                    const char *data_type);  /* IN */

#define BSON_BYTE_BUFFER_SIZE 1024

#ifndef HOST_NAME_HASH_MAX
#define HOST_NAME_HASH_MAX 256
#endif

/* See the type list in http://bsonspec.org/spec.html. */
#define BSON_TYPE_DOUBLE        1
#define BSON_TYPE_STRING        2
#define BSON_TYPE_DOCUMENT      3
#define BSON_TYPE_ARRAY         4
#define BSON_TYPE_BOOLEAN       8
#define BSON_TYPE_SYMBOL        0x0E
#define BSON_TYPE_INT32         0x10
#define BSON_TYPE_INT64         0x12

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

VALUE rb_bson_byte_buffer_allocate(VALUE klass);
VALUE rb_bson_byte_buffer_initialize(int argc, VALUE *argv, VALUE self);
VALUE rb_bson_byte_buffer_length(VALUE self);
VALUE rb_bson_byte_buffer_get_byte(VALUE self);
VALUE rb_bson_byte_buffer_get_bytes(VALUE self, VALUE i);
VALUE rb_bson_byte_buffer_get_cstring(VALUE self);
VALUE rb_bson_byte_buffer_get_decimal128_bytes(VALUE self);
VALUE rb_bson_byte_buffer_get_double(VALUE self);
VALUE rb_bson_byte_buffer_get_int32(VALUE self);
VALUE rb_bson_byte_buffer_get_uint32(VALUE self);
VALUE rb_bson_byte_buffer_get_int64(VALUE self);
VALUE rb_bson_byte_buffer_get_string(VALUE self);
VALUE rb_bson_byte_buffer_get_hash(int argc, VALUE *argv, VALUE self);
VALUE rb_bson_byte_buffer_get_array(int argc, VALUE *argv, VALUE self);
VALUE rb_bson_byte_buffer_put_byte(VALUE self, VALUE byte);
VALUE rb_bson_byte_buffer_put_bytes(VALUE self, VALUE bytes);
VALUE rb_bson_byte_buffer_put_cstring(VALUE self, VALUE string);
VALUE rb_bson_byte_buffer_put_decimal128(VALUE self, VALUE low, VALUE high);
VALUE rb_bson_byte_buffer_put_double(VALUE self, VALUE f);
VALUE rb_bson_byte_buffer_put_int32(VALUE self, VALUE i);
VALUE rb_bson_byte_buffer_put_uint32(VALUE self, VALUE i);
VALUE rb_bson_byte_buffer_put_int64(VALUE self, VALUE i);
VALUE rb_bson_byte_buffer_put_string(VALUE self, VALUE string);
VALUE rb_bson_byte_buffer_put_symbol(VALUE self, VALUE symbol);
VALUE rb_bson_byte_buffer_put_hash(VALUE self, VALUE hash, VALUE validating_keys);
VALUE rb_bson_byte_buffer_put_array(VALUE self, VALUE array, VALUE validating_keys);
VALUE rb_bson_byte_buffer_read_position(VALUE self);
VALUE rb_bson_byte_buffer_replace_int32(VALUE self, VALUE index, VALUE i);
VALUE rb_bson_byte_buffer_rewind(VALUE self);
VALUE rb_bson_byte_buffer_write_position(VALUE self);
VALUE rb_bson_byte_buffer_to_s(VALUE self);
VALUE rb_bson_object_id_generator_next(int argc, VALUE* args, VALUE self);

size_t rb_bson_byte_buffer_memsize(const void *ptr);
void rb_bson_byte_buffer_free(void *ptr);
void rb_bson_expand_buffer(byte_buffer_t* buffer_ptr, size_t length);
void rb_bson_generate_machine_id(VALUE rb_md5_class, char *rb_bson_machine_id);

VALUE pvt_const_get_2(const char *c1, const char *c2);
VALUE pvt_const_get_3(const char *c1, const char *c2, const char *c3);

#define BSON_MODE_DEFAULT       0
#define BSON_MODE_BSON          1

int pvt_get_mode_option(int argc, VALUE *argv);

/**
 * The counter for incrementing object ids.
 */
extern uint32_t rb_bson_object_id_counter;

extern VALUE rb_bson_registry;

extern VALUE rb_bson_illegal_key;

extern const rb_data_type_t rb_byte_buffer_data_type;

extern VALUE _ref_str, _id_str, _db_str;
