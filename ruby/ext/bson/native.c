#include <ruby.h>
#include <stdint.h>

/*
 * For 64 byte systems we convert to longs, for 32 byte systems we convert
 * to a long long.
 */
#if SIZEOF_LONG == 8
#define NUM2INT64(v) NUM2LONG(v)
#else
#define NUM2INT64(v) NUM2LL(v)
#endif

/*
 * Convert the Ruby integer into a BSON as per the 32 bit specification,
 * which is 4 bytes.
 *
 * @example Convert the integer to 32bit BSON.
 *    rb_integer_to_bson_int32(128);
 *
 * @param [ Integer ] self The Ruby integer.
 *
 * @return [ String ] A Ruby string of raw bytes.
 *
 * @since 2.0.0
 */
static VALUE rb_integer_to_bson_int32(VALUE self)
{
  const int32_t v = NUM2INT(self);
  const char bytes[4] = {
    v & 255,
    (v >> 8) & 255,
    (v >> 16) & 255,
    (v >> 24) & 255
  };
  return rb_str_new(bytes, 4);
}

/*
 * Convert the Ruby integer into a BSON as per the 64 bit specification,
 * which is 8 bytes.
 *
 * @example Convert the integer to 64bit BSON.
 *    rb_integer_to_bson_int64(128);
 *
 * @param [ Integer ] self The Ruby integer.
 *
 * @return [ String ] A Ruby string of raw bytes.
 *
 * @since 2.0.0
 */
static VALUE rb_integer_to_bson_int64(VALUE self)
{
  const int64_t v = NUM2INT64(self);
  const char bytes[8] = {
    v & 255,
    (v >> 8) & 255,
    (v >> 16) & 255,
    (v >> 24) & 255,
    (v >> 32) & 255,
    (v >> 40) & 255,
    (v >> 48) & 255,
    (v >> 56) & 255
  };
  return rb_str_new(bytes, 8);
}

/*
 * Initialize the bson c extension.
 *
 * @since 2.0.0
 */
void Init_native()
{
  VALUE bson = rb_const_get(rb_cObject, rb_intern("BSON"));

  VALUE integer = rb_const_get(bson, rb_intern("Integer"));
  rb_remove_method(integer, "to_bson_int32");
  rb_define_private_method(integer, "to_bson_int32", rb_integer_to_bson_int32, 0);
  rb_remove_method(integer, "to_bson_int64");
  rb_define_private_method(integer, "to_bson_int64", rb_integer_to_bson_int64, 0);
}
