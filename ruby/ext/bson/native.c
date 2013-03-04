#include <ruby.h>
#include <stdint.h>

static VALUE rb_integer_to_bson(VALUE self)
{
  /* const int32_t v = NUM2INT(self); */
  /* const char bytes[4] = { v & 255, (v >> 8) & 255, (v >> 16) & 255, (v >> 24) & 255 }; */
  /* return rb_str_new(bytes, 4); */
}

void Init_native()
{
  /* VALUE bson = rb_const_get(rb_cObject, rb_intern("BSON")); */

  /* VALUE integer = rb_const_get(bson, rb_intern("Integer")); */
  /* rb_remove_method(integer, "to_bson"); */
  /* rb_define_method(integer, "to_bson", rb_integer_to_bson, 0); */
}
