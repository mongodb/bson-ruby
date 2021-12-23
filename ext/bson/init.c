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
 * The counter for incrementing object ids.
 */
uint32_t rb_bson_object_id_counter;


VALUE rb_bson_registry;

VALUE rb_bson_illegal_key;

const rb_data_type_t rb_byte_buffer_data_type = {
  "bson/byte_buffer",
  { NULL, rb_bson_byte_buffer_free, rb_bson_byte_buffer_memsize }
};

VALUE _ref_str, _id_str, _db_str;

/**
 * Initialize the bson_native extension.
 */
void Init_bson_native()
{
  char rb_bson_machine_id[256];

  _ref_str = rb_str_new_cstr("$ref");
  rb_gc_register_mark_object(_ref_str);
  _id_str = rb_str_new_cstr("$id");
  rb_gc_register_mark_object(_id_str);
  _db_str = rb_str_new_cstr("$db");
  rb_gc_register_mark_object(_db_str);

  VALUE rb_bson_module = rb_define_module("BSON");

  /* Document-class: BSON::ByteBuffer
   *
   * Stores BSON-serialized data and provides efficient serialization and
   * deserialization of common Ruby classes using native code.
   */
  VALUE rb_byte_buffer_class = rb_define_class_under(rb_bson_module, "ByteBuffer", rb_cObject);

  VALUE rb_bson_object_id_class = rb_const_get(rb_bson_module, rb_intern("ObjectId"));
  VALUE rb_bson_object_id_generator_class = rb_const_get(rb_bson_object_id_class, rb_intern("Generator"));
  VALUE rb_digest_class = rb_const_get(rb_cObject, rb_intern("Digest"));
  VALUE rb_md5_class = rb_const_get(rb_digest_class, rb_intern("MD5"));

  rb_bson_illegal_key = rb_const_get(rb_const_get(rb_bson_module, rb_intern("String")),rb_intern("IllegalKey"));
  rb_gc_register_mark_object(rb_bson_illegal_key);

  rb_define_alloc_func(rb_byte_buffer_class, rb_bson_byte_buffer_allocate);
  rb_define_method(rb_byte_buffer_class, "initialize", rb_bson_byte_buffer_initialize, -1);

  /*
   * call-seq:
   *   buffer.length -> Fixnum
   *
   * Returns the number of bytes available to be read in the buffer.
   *
   * When a buffer is being written to, each added byte increases its length.
   * When a buffer is being read from, each read byte decreases its length.
   */
  rb_define_method(rb_byte_buffer_class, "length", rb_bson_byte_buffer_length, 0);

  /*
   * call-seq:
   *   buffer.read_position -> Fixnum
   *
   * Returns the read position in the buffer.
   */
  rb_define_method(rb_byte_buffer_class, "read_position", rb_bson_byte_buffer_read_position, 0);

  rb_define_method(rb_byte_buffer_class, "get_byte", rb_bson_byte_buffer_get_byte, 0);
  rb_define_method(rb_byte_buffer_class, "get_bytes", rb_bson_byte_buffer_get_bytes, 1);
  rb_define_method(rb_byte_buffer_class, "get_cstring", rb_bson_byte_buffer_get_cstring, 0);
  rb_define_method(rb_byte_buffer_class, "get_decimal128_bytes", rb_bson_byte_buffer_get_decimal128_bytes, 0);
  rb_define_method(rb_byte_buffer_class, "get_double", rb_bson_byte_buffer_get_double, 0);

  /*
   * call-seq:
   *   buffer.get_hash(**options) -> Hash
   *
   * Reads a document from the byte buffer and returns it as a BSON::Document.
   *
   * @option options [ nil | :bson ] :mode Decoding mode to use.
   *
   * @return [ BSON::Document ] The decoded document.
   */
  rb_define_method(rb_byte_buffer_class, "get_hash", rb_bson_byte_buffer_get_hash, -1);

  /*
   * call-seq:
   *   buffer.get_array(**options) -> Array
   *
   * Reads an array from the byte buffer.
   *
   * @option options [ nil | :bson ] :mode Decoding mode to use.
   *
   * @return [ Array ] The decoded array.
   */
  rb_define_method(rb_byte_buffer_class, "get_array", rb_bson_byte_buffer_get_array, -1);

  rb_define_method(rb_byte_buffer_class, "get_int32", rb_bson_byte_buffer_get_int32, 0);
  
  /*
   * call-seq:
   *   buffer.get_uint32(buffer) -> Fixnum
   *
   * Reads an unsigned 32 bit number from the byte buffer.
   *
   * @return [ Fixnum ] The unsigned 32 bits integer from the buffer
   *
   * @api private
   */
  rb_define_method(rb_byte_buffer_class, "get_uint32", rb_bson_byte_buffer_get_uint32, 0);
  rb_define_method(rb_byte_buffer_class, "get_int64", rb_bson_byte_buffer_get_int64, 0);
  rb_define_method(rb_byte_buffer_class, "get_string", rb_bson_byte_buffer_get_string, 0);

  /*
   * call-seq:
   *   buffer.write_position -> Fixnum
   *
   * Returns the write position in the buffer.
   */
  rb_define_method(rb_byte_buffer_class, "write_position", rb_bson_byte_buffer_write_position, 0);

  /*
   * call-seq:
   *   buffer.put_byte(binary_str) -> ByteBuffer
   *
   * Writes the specified byte string, which must be of length 1,
   * to the byte buffer.
   *
   * Returns the modified +self+.
   */
  rb_define_method(rb_byte_buffer_class, "put_byte", rb_bson_byte_buffer_put_byte, 1);

  /*
   * call-seq:
   *   buffer.put_bytes(binary_str) -> ByteBuffer
   *
   * Writes the specified byte string to the byte buffer.
   *
   * This method writes exactly the provided byte string - in particular, it
   * does not prepend the length, and does not append a null byte at the end.
   *
   * Returns the modified +self+.
   */
  rb_define_method(rb_byte_buffer_class, "put_bytes", rb_bson_byte_buffer_put_bytes, 1);

  /*
   * call-seq:
   *   buffer.put_string(str) -> ByteBuffer
   *
   * Writes the specified string to the byte buffer as a BSON string.
   *
   * Unlike #put_bytes, this method writes the provided byte string as
   * a "BSON string" - the string is prefixed with its length and suffixed
   * with a null byte. The byte string may contain null bytes itself thus
   * the null terminator is redundant, but it is required by the BSON
   * specification.
   *
   * +str+ must either already be in UTF-8 encoding or be a string encodable
   * to UTF-8. In particular, a string in BINARY/ASCII-8BIT encoding is
   * generally not suitable for this method. +EncodingError+ will be raised
   * if +str+ cannot be encoded in UTF-8, or if +str+ claims to be encoded in
   * UTF-8 but contains bytes/byte sequences which are not valid in UTF-8.
   * Use #put_bytes to write arbitrary byte strings to the buffer.
   *
   * Returns the modified +self+.
   */
  rb_define_method(rb_byte_buffer_class, "put_string", rb_bson_byte_buffer_put_string, 1);

  /**
   * call-seq:
   *   buffer.put_cstring(obj) -> ByteBuffer
   *
   * Converts +obj+ to a string, which must not contain any null bytes, and
   * which must be valid UTF-8, and writes the string to the buffer as a
   * BSON cstring. +obj+ can be an instance of String, Symbol or Fixnum.
   *
   * If the string serialization of +obj+ contains null bytes, this method
   * raises +ArgumentError+. If +obj+ is of an unsupported type, this method
   * raises +TypeError+.
   *
   * BSON cstring serialization contains no length of the string (relying
   * instead on the null terminator), unlike the BSON string serialization.
   */
  rb_define_method(rb_byte_buffer_class, "put_cstring", rb_bson_byte_buffer_put_cstring, 1);

  /**
   * call-seq:
   *   buffer.put_symbol(sym) -> ByteBuffer
   *
   * Converts +sym+ to a string and writes the resulting string to the byte
   * buffer.
   *
   * The symbol may contain null bytes.
   *
   * The symbol value is assumed to be encoded in UTF-8. If the symbol value
   * contains bytes or byte sequences that are not valid in UTF-8, this method
   * raises +EncodingError+.
   *
   * Note: due to the string conversion, a symbol written to the buffer becomes
   * indistinguishable from a string with the same value written to the buffer.
   */
  rb_define_method(rb_byte_buffer_class, "put_symbol", rb_bson_byte_buffer_put_symbol, 1);

  /*
   * call-seq:
   *   buffer.put_int32(fixnum) -> ByteBuffer
   *
   * Writes a 32-bit integer value to the buffer.
   *
   * If the argument cannot be represented in 32 bits, raises RangeError.
   *
   * Returns the modified +self+.
   */
  rb_define_method(rb_byte_buffer_class, "put_int32", rb_bson_byte_buffer_put_int32, 1);

  /*
   * call-seq:
   *   buffer.put_uint32(fixnum) -> ByteBuffer
   *
   * Writes an unsigned 32-bit integer value to the buffer.
   *
   * If the argument cannot be represented in 32 bits, raises RangeError.
   *
   * Returns the modified +self+.
   *
   * @api private
   *
   */
  rb_define_method(rb_byte_buffer_class, "put_uint32", rb_bson_byte_buffer_put_uint32, 1);

  /*
   * call-seq:
   *   buffer.put_int64(fixnum) -> ByteBuffer
   *
   * Writes a 64-bit integer value to the buffer.
   *
   * If the argument cannot be represented in 64 bits, raises RangeError.
   *
   * Returns the modified +self+.
   */
  rb_define_method(rb_byte_buffer_class, "put_int64", rb_bson_byte_buffer_put_int64, 1);

  /*
   * call-seq:
   *   buffer.put_double(double) -> ByteBuffer
   *
   * Writes a 64-bit floating point value to the buffer.
   *
   * Returns the modified +self+.
   */
  rb_define_method(rb_byte_buffer_class, "put_double", rb_bson_byte_buffer_put_double, 1);

  /*
   * call-seq:
   *   buffer.put_decimal128(low_64bit, high_64bit) -> ByteBuffer
   *
   * Writes a 128-bit Decimal128 value to the buffer.
   *
   * +low_64bit+ and +high_64bit+ are Fixnum objects containing the low and
   * the high parts of the 128-bit Decimal128 value, respectively.
   *
   * Returns the modified +self+.
   */
  rb_define_method(rb_byte_buffer_class, "put_decimal128", rb_bson_byte_buffer_put_decimal128, 2);

  /*
   * call-seq:
   *   buffer.put_hash(hash, validating_keys) -> ByteBuffer
   *
   * Writes a Hash into the byte buffer.
   *
   * Returns the modified +self+.
   */
  rb_define_method(rb_byte_buffer_class, "put_hash", rb_bson_byte_buffer_put_hash, 2);

  /*
   * call-seq:
   *   buffer.put_array(array) -> ByteBuffer
   *
   * Writes an Array into the byte buffer.
   *
   * Returns the modified +self+.
   */
  rb_define_method(rb_byte_buffer_class, "put_array", rb_bson_byte_buffer_put_array, 2);

  /*
   * call-seq:
   *   buffer.replace_int32(position, fixnum) -> ByteBuffer
   *
   * Replaces a 32-bit integer value at the specified position in the buffer.
   *
   * The position must be a non-negative integer, and must be completely
   * contained within the data already written. For example, if the buffer has
   * the write position of 12, the acceptable range of positions for this
   * method is 0..8.
   *
   * If the argument cannot be represented in 32 bits, raises RangeError.
   *
   * Returns the modified +self+.
   */
  rb_define_method(rb_byte_buffer_class, "replace_int32", rb_bson_byte_buffer_replace_int32, 2);

  /*
   * call-seq:
   *   buffer.rewind! -> ByteBuffer
   *
   * Resets the read position to the beginning of the byte buffer.
   *
   * Note: +rewind!+ does not change the buffer's write position.
   *
   * Returns the modified +self+.
   */
  rb_define_method(rb_byte_buffer_class, "rewind!", rb_bson_byte_buffer_rewind, 0);

  /*
   * call-seq:
   *   buffer.to_s -> String
   *
   * Returns the contents of the buffer as a binary string.
   *
   * If the buffer is used for reading, the returned contents is the data
   * that was not yet read. If the buffer is used for writing, the returned
   * contents is the complete data that has been written so far.
   *
   * Note: this method copies the buffer's contents into a newly allocated
   * +String+ instance. It does not return a reference to the data stored in
   * the buffer itself.
   */
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
  rb_gc_register_mark_object(rb_bson_registry);
}
