#include <ruby.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>

/**
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

/**
 * Holds the machine id for object id generation.
 *
 * @since 2.0.0
 */
static char rb_bson_machine_id[3] = "abc";

/**
 * The counter for incrementing object ids.
 *
 * @since 2.0.0
 */
static unsigned int rb_bson_object_id_counter = 0;

/**
 * Get the current time in milliseconds, used in object id generation.
 *
 * @example Get the current time in milliseconds.
 *    rb_current_time_milliseconds();
 *
 * @return [ int ] The current time in millis.
 *
 * @since 2.0.0
 */
static unsigned long rb_current_time_milliseconds()
{
  struct timeval time;
  gettimeofday(&time, NULL);
  return (time.tv_sec) * 1000 + (time.tv_usec) / 1000;
}

/**
 * Generate the data for the next object id.
 *
 * @example Generate the data for the next object id.
 *    rb_object_id_generator_next(0, NULL, object_id);
 *
 * @param [ int ] argc The argument count.
 * @param [ Time ] time The optional Ruby time.
 * @param [ BSON::ObjectId ] self The object id.
 *
 * @return [ String ] The raw bytes for the id.
 *
 * @since 2.0.0
 */
static VALUE rb_object_id_generator_next(int argc, VALUE* time, VALUE self)
{
  char bytes[12];
  unsigned long t;
  unsigned short pid = htons(getpid());

  if (argc == 0 || (argc == 1 && *time == Qnil)) {
    t = rb_current_time_milliseconds();
  }
  else {
    t = htonl(NUM2UINT(rb_funcall(*time, rb_intern("to_i"), 0)));
  }

  memcpy(&bytes, &time, 4);
  memcpy(&bytes[4], rb_bson_machine_id, 3);
  memcpy(&bytes[7], &pid, 2);
  memcpy(&bytes[9], (unsigned char*) &rb_bson_object_id_counter, 3);
  rb_bson_object_id_counter++;
  return rb_str_new(bytes, 12);
}

/**
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

/**
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

/**
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

/**
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

/**
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

/**
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
  VALUE object_id = rb_const_get(bson, rb_intern("ObjectId"));
  VALUE generator = rb_const_get(object_id, rb_intern("Generator"));

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

  // Setup the machine id for object id generation.
  /* memcpy(rb_bson_machine_id, RSTRING_PTR(machine_id), 16); */
  rb_undef_method(generator, "next");
  rb_define_method(generator, "next", rb_object_id_generator_next, -1);
}
