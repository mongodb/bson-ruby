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
#include <ruby/encoding.h>

static void pvt_validate_length(byte_buffer_t *b);
static uint8_t pvt_get_type_byte(byte_buffer_t *b);
static VALUE pvt_get_int32(byte_buffer_t *b);
static VALUE pvt_get_int64(byte_buffer_t *b, int argc, VALUE *argv);
static VALUE pvt_get_double(byte_buffer_t *b);
static VALUE pvt_get_string(byte_buffer_t *b);
static VALUE pvt_get_symbol(byte_buffer_t *b, int argc, VALUE *argv);
static VALUE pvt_get_boolean(byte_buffer_t *b);
static VALUE pvt_read_field(byte_buffer_t *b, VALUE rb_buffer, uint8_t type, int argc, VALUE *argv);
static void pvt_skip_cstring(byte_buffer_t *b);

/**
 * validate the buffer contains the amount of bytes the array / hash claimns
 * and that it is null terminated
 */
void pvt_validate_length(byte_buffer_t *b)
{
  int32_t length;
  
  ENSURE_BSON_READ(b, 4);
  memcpy(&length, READ_PTR(b), 4);
  length = BSON_UINT32_TO_LE(length);

  /* minimum valid length is 4 (byte count) + 1 (terminating byte) */ 
  if(length >= 5){
    ENSURE_BSON_READ(b, length);

    /* The last byte should be a null byte: it should be at length - 1 */
    if( *(READ_PTR(b) + length - 1) != 0 ){
      rb_raise(rb_eRangeError, "Buffer should have contained null terminator at %zu but contained %d", b->read_position + (size_t)length, (int)*(READ_PTR(b) + length));
    }
    b->read_position += 4;
  }
  else{
    rb_raise(rb_eRangeError, "Buffer contained invalid length %d at %zu", length, b->read_position);
  }
}

/**
 * Read a single field from a hash or array
 */
VALUE pvt_read_field(byte_buffer_t *b, VALUE rb_buffer, uint8_t type, int argc, VALUE *argv)
{
  switch(type) {
    case BSON_TYPE_INT32: return pvt_get_int32(b);
    case BSON_TYPE_INT64: return pvt_get_int64(b, argc, argv);
    case BSON_TYPE_DOUBLE: return pvt_get_double(b);
    case BSON_TYPE_STRING: return pvt_get_string(b);
    case BSON_TYPE_SYMBOL: return pvt_get_symbol(b, argc, argv);
    case BSON_TYPE_ARRAY: return rb_bson_byte_buffer_get_array(argc, argv, rb_buffer);
    case BSON_TYPE_DOCUMENT: return rb_bson_byte_buffer_get_hash(argc, argv, rb_buffer);
    case BSON_TYPE_BOOLEAN: return pvt_get_boolean(b);
    default:
    {
      VALUE klass = rb_funcall(rb_bson_registry,rb_intern("get"),1, INT2FIX(type));
      VALUE value = rb_funcall(klass, rb_intern("from_bson"),1, rb_buffer);
      RB_GC_GUARD(klass);
      return value;
    }
  }
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

uint8_t pvt_get_type_byte(byte_buffer_t *b){
  int8_t byte;
  ENSURE_BSON_READ(b, 1);
  byte = *READ_PTR(b);
  b->read_position += 1;
  return (uint8_t)byte;
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

VALUE pvt_get_boolean(byte_buffer_t *b){
  VALUE result = Qnil;
  ENSURE_BSON_READ(b, 1);
  result = *READ_PTR(b) == 1 ? Qtrue: Qfalse;
  b->read_position += 1;
  return result;
}

/**
 * Get a string from the buffer.
 */
VALUE rb_bson_byte_buffer_get_string(VALUE self)
{
  byte_buffer_t *b;

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  return pvt_get_string(b);
}

VALUE pvt_get_string(byte_buffer_t *b)
{
  int32_t length;
  int32_t length_le;
  VALUE string;

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
 * Reads a UTF-8 string out of the byte buffer. If the argc/argv arguments
 * have a :mode option with the value of :bson, wraps the string in a
 * BSON::Symbol::Raw. Returns either the read string or the BSON::Symbol::Raw
 * instance.
 */
VALUE pvt_get_symbol(byte_buffer_t *b, int argc, VALUE *argv)
{
  VALUE value = pvt_get_string(b);
  
  if (pvt_get_mode_option(argc, argv) == BSON_MODE_BSON) {
    VALUE klass = pvt_const_get_3("BSON", "Symbol", "Raw");
    value = rb_funcall(klass, rb_intern("new"), 1, value);
    RB_GC_GUARD(klass);
  }
  
  return value;
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
 * Reads but does not return a cstring from the buffer.
 */
void pvt_skip_cstring(byte_buffer_t *b)
{
  int length;
  length = (int)strlen(READ_PTR(b));
  ENSURE_BSON_READ(b, length);
  b->read_position += length + 1;
}

/**
 * Get a int32 from the buffer.
 */
VALUE rb_bson_byte_buffer_get_int32(VALUE self)
{
  byte_buffer_t *b;

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  return pvt_get_int32(b);
}

VALUE pvt_get_int32(byte_buffer_t *b)
{
  int32_t i32;

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
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  return pvt_get_int64(b, 0, NULL);
}

VALUE pvt_get_int64(byte_buffer_t *b, int argc, VALUE *argv)
{
  int64_t i64;
  VALUE num;

  ENSURE_BSON_READ(b, 8);
  memcpy(&i64, READ_PTR(b), 8);
  b->read_position += 8;
  num = LL2NUM(BSON_UINT64_FROM_LE(i64));
  
  if (pvt_get_mode_option(argc, argv) == BSON_MODE_BSON) {
    VALUE klass = rb_funcall(rb_bson_registry,rb_intern("get"),1, INT2FIX(BSON_TYPE_INT64));
    VALUE value = rb_funcall(klass, rb_intern("new"), 1, num);
    RB_GC_GUARD(klass);
    return value;
  } else {
    return num;
  }
  
  RB_GC_GUARD(num);
}

/**
 * Get a double from the buffer.
 */
VALUE rb_bson_byte_buffer_get_double(VALUE self)
{
  byte_buffer_t *b;

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  return pvt_get_double(b);
}

VALUE pvt_get_double(byte_buffer_t *b)
{
  double d;

  ENSURE_BSON_READ(b, 8);
  memcpy(&d, READ_PTR(b), 8);
  b->read_position += 8;
  return DBL2NUM(BSON_DOUBLE_FROM_LE(d));
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

VALUE rb_bson_byte_buffer_get_hash(int argc, VALUE *argv, VALUE self){
  VALUE doc = Qnil;
  byte_buffer_t *b = NULL;
  uint8_t type;
  VALUE cDocument = pvt_const_get_2("BSON", "Document");

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);

  pvt_validate_length(b);

  doc = rb_funcall(cDocument, rb_intern("allocate"), 0);

  while((type = pvt_get_type_byte(b)) != 0){
    VALUE field = rb_bson_byte_buffer_get_cstring(self);
    rb_hash_aset(doc, field, pvt_read_field(b, self, type, argc, argv));
    RB_GC_GUARD(field);
  }
  return doc;
}

VALUE rb_bson_byte_buffer_get_array(int argc, VALUE *argv, VALUE self){
  byte_buffer_t *b;
  VALUE array = Qnil;
  uint8_t type;

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);

  pvt_validate_length(b);

  array = rb_ary_new();
  while((type = pvt_get_type_byte(b)) != 0){
    pvt_skip_cstring(b);
    rb_ary_push(array,  pvt_read_field(b, self, type, argc, argv));
  }
  RB_GC_GUARD(array);
  return array;
}
