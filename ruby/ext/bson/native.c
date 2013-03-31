#include <ruby.h>
#include <stdint.h>

/*
 * For 64 byte systems we convert to longs, for 32 byte systems we convert
 * to a long long.
 *
 * @since 2.0.0
 */
#if SIZEOF_LONG == 8
#define NUM2INT64(v) NUM2LONG(v)
#define INT642NUM(v) LONG2NUM(v)
#else
#define NUM2INT64(v) NUM2LL(v)
#define INT642NUM(v) LL2NUM(v)
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
 * Convert the provided raw bytes into a 32bit Ruby integer.
 *
 * @example Convert the bytes to an Integer.
 *    rb_integer_from_bson_int32(Int32, bytes);
 *
 * @param [ BSON::Int32 ] self The Int32 eigenclass.
 * @param [ String ] bytes The raw bytes.
 *
 * @return [ Integer ] The Ruby integer.
 *
 * @since 2.0.0
 */
static VALUE rb_integer_from_bson_int32(VALUE self, VALUE bson)
{
  const uint8_t *v = (const uint8_t*) RSTRING_PTR(bson);
  const uint32_t integer = v[0] + (v[1] << 8) + (v[2] << 16) + (v[3] << 24);
  return INT2NUM(integer);
}

/*
 * Convert the provided raw bytes into a 64bit Ruby integer.
 *
 * @example Convert the bytes to an Integer.
 *    rb_integer_from_bson_int64(Int64, bytes);
 *
 * @param [ BSON::Int64 ] self The Int64 eigenclass.
 * @param [ String ] bytes The raw bytes.
 *
 * @return [ Integer ] The Ruby integer.
 *
 * @since 2.0.0
 */
static VALUE rb_integer_from_bson_int64(VALUE self, VALUE bson)
{
  const uint8_t *v = (const uint8_t*) RSTRING_PTR(bson);
  const int64_t lower = v[0] + (v[1] << 8) + (v[2] << 16) + (v[3] << 24);
  const int64_t upper = v[4] + (v[5] << 8) + (v[6] << 16) + (v[7] << 24);
  const uint64_t integer = lower + (upper << 32);
  return INT642NUM(integer);
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
 * Converts the milliseconds time to the raw BSON bytes. We need to
 * explicitly convert using 64 bit here.
 *
 * @example Convert the milliseconds value to BSON bytes.
 *    rb_time_to_bson(time, 2124132340000);
 *
 * @param [ Time ] self The Ruby Time object.
 * @param [ Integer ] milliseconds The milliseconds pre/post epoch.
 *
 * @return [ String ] A Ruby string of raw bytes.
 *
 * @since 2.0.0
 */
static VALUE rb_time_to_bson(VALUE self, VALUE milliseconds)
{
  return rb_integer_to_bson_int64(milliseconds);
}

/*
 * Initialize the bson c extension.
 *
 * @since 2.0.0
 */
void Init_native()
{
  // Get all the constants to be used in the extensions.
  VALUE bson = rb_const_get(rb_cObject, rb_intern("BSON"));
  VALUE integer = rb_const_get(bson, rb_intern("Integer"));
  VALUE time = rb_const_get(bson, rb_intern("Time"));
  VALUE int32 = rb_const_get(bson, rb_intern("Int32"));
  VALUE int32_class = rb_singleton_class(int32);
  VALUE int64 = rb_const_get(bson, rb_intern("Int64"));
  VALUE int64_class = rb_singleton_class(int64);

  // Redefine the serialization methods on the Integer class.
  rb_undef_method(integer, "to_bson_int32");
  rb_define_private_method(integer, "to_bson_int32", rb_integer_to_bson_int32, 0);
  rb_undef_method(integer, "to_bson_int64");
  rb_define_private_method(integer, "to_bson_int64", rb_integer_to_bson_int64, 0);

  // Redefine deserialization methods on Int32 class.
  rb_undef_method(int32_class, "from_bson_int32");
  rb_define_private_method(int32_class, "from_bson_int32", rb_integer_from_bson_int32, 1);

  // Redefine deserialization methods on Int64 class.
  rb_undef_method(int64_class, "from_bson_int64");
  rb_define_private_method(int64_class, "from_bson_int64", rb_integer_from_bson_int64, 1);

  // Redefine the serialization methods on the time class.
  rb_undef_method(time, "to_bson_time");
  rb_define_method(time, "to_bson_time", rb_time_to_bson, 1);
}
