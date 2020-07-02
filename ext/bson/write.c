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
#include <ruby/encoding.h>

typedef struct{
  byte_buffer_t *b;
  VALUE buffer;
  VALUE validating_keys;
} put_hash_context;

static void pvt_replace_int32(byte_buffer_t *b, int32_t position, int32_t newval);
static void pvt_put_field(byte_buffer_t *b, VALUE rb_buffer, VALUE val, VALUE validating_keys);
static void pvt_put_byte(byte_buffer_t *b, const char byte);
static void pvt_put_int32(byte_buffer_t *b, const int32_t i32);
static void pvt_put_uint32(byte_buffer_t *b, const uint32_t i32);
static void pvt_put_int64(byte_buffer_t *b, const int64_t i);
static void pvt_put_double(byte_buffer_t *b, double f);
static void pvt_put_cstring(byte_buffer_t *b, const char *str, int32_t length, const char *data_type);
static void pvt_put_bson_key(byte_buffer_t *b, VALUE string, VALUE validating_keys);
static VALUE pvt_bson_byte_buffer_put_bson_partial_string(VALUE self, const char *str, int32_t length);
static VALUE pvt_bson_byte_buffer_put_binary_string(VALUE self, const char *str, int32_t length);

static int fits_int32(int64_t i64){
  return i64 >= INT32_MIN && i64 <= INT32_MAX;
}

void pvt_put_field(byte_buffer_t *b, VALUE rb_buffer, VALUE val, VALUE validating_keys){
  switch(TYPE(val)){
    case T_BIGNUM:
    case T_FIXNUM:{
      int64_t i64= NUM2LL(val);
      if(fits_int32(i64)){
        pvt_put_int32(b, (int32_t)i64);
      }else{
        pvt_put_int64(b, i64);
      }
      break;
    }
    case T_FLOAT:
      pvt_put_double(b, NUM2DBL(val));
      break;
    case T_ARRAY:
      rb_bson_byte_buffer_put_array(rb_buffer, val, validating_keys);
      break;
    case T_TRUE:
      pvt_put_byte(b, 1);
      break;
    case T_FALSE:
      pvt_put_byte(b, 0);
      break;
    case T_HASH:
      rb_bson_byte_buffer_put_hash(rb_buffer, val, validating_keys);
      break;
    default:{
      rb_funcall(val, rb_intern("to_bson"), 2, rb_buffer, validating_keys);
      break;
    }
  }
}

void pvt_put_byte(byte_buffer_t *b, const char byte)
{
  ENSURE_BSON_WRITE(b, 1);
  *WRITE_PTR(b) = byte;
  b->write_position += 1;

}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_put_byte(VALUE self, VALUE byte)
{
  byte_buffer_t *b;
  const char *str;
  size_t length;

  if (!RB_TYPE_P(byte, T_STRING))
    rb_raise(rb_eArgError, "A string argument is required for put_byte");

  str = RSTRING_PTR(byte);
  length = RSTRING_LEN(byte);
  
  if (length != 1) {
    rb_raise(rb_eArgError, "put_byte requires a string of length 1");
  }

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, 1);
  memcpy(WRITE_PTR(b), str, 1);
  b->write_position += 1;

  return self;
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_put_bytes(VALUE self, VALUE bytes)
{
  byte_buffer_t *b;
  const char *str;
  size_t length;

  if (!RB_TYPE_P(bytes, T_STRING) && !RB_TYPE_P(bytes, RUBY_T_DATA))
    rb_raise(rb_eArgError, "Invalid input");

  str = RSTRING_PTR(bytes);
  length = RSTRING_LEN(bytes);

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, length);
  memcpy(WRITE_PTR(b), str, length);
  b->write_position += length;
  return self;
}

/* write the byte denoting the BSON type for the passed object */
void pvt_put_type_byte(byte_buffer_t *b, VALUE val){
  char type_byte;
  
  switch (TYPE(val)){
    case T_BIGNUM:
    case T_FIXNUM:
      if (fits_int32(NUM2LL(val))) {
        type_byte = BSON_TYPE_INT32;
      } else {
        type_byte = BSON_TYPE_INT64;
      }
      break;
    case T_STRING:
      type_byte = BSON_TYPE_STRING;
      break;
    case T_ARRAY:
      type_byte = BSON_TYPE_ARRAY;
      break;
    case T_TRUE:
    case T_FALSE:
      type_byte = BSON_TYPE_BOOLEAN;
      break;
    case T_HASH:
      type_byte = BSON_TYPE_DOCUMENT;
      break;
    case T_FLOAT:
      type_byte = BSON_TYPE_DOUBLE;
      break;
    default: {
      VALUE type;
      VALUE responds = rb_funcall(val, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("bson_type")));
      if (!RTEST(responds)) {
        VALUE klass = pvt_const_get_3("BSON", "Error", "UnserializableClass");
        VALUE val_str = rb_funcall(val, rb_intern("to_s"), 0);
        rb_raise(klass, "Value does not define its BSON serialized type: %s", RSTRING_PTR(val_str));
      }
      type = rb_funcall(val, rb_intern("bson_type"), 0);
      type_byte = *RSTRING_PTR(type);
      RB_GC_GUARD(type);
      break;
    }
  }
  
  pvt_put_byte(b, type_byte);
}

/**
 * Write a binary string (i.e. one potentially including null bytes)
 * to byte buffer. length is the number of bytes to write.
 * If str is null terminated, length does not include the terminating null.
 */
VALUE pvt_bson_byte_buffer_put_binary_string(VALUE self, const char *str, int32_t length)
{
  byte_buffer_t *b;
  int32_t length_le;

  rb_bson_utf8_validate(str, length, true, "String");

  /* Even though we are storing binary data, and including the length
   * of it, the bson spec still demands the (useless) trailing null.
   */
  length_le = BSON_UINT32_TO_LE(length + 1);

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, length + 5);
  memcpy(WRITE_PTR(b), &length_le, 4);
  b->write_position += 4;
  memcpy(WRITE_PTR(b), str, length);
  b->write_position += length;
  pvt_put_byte(b, 0);

  return self;
}

/**
 * Encodes +string+ to UTF-8. If +string+ is already in UTF-8, validates that
 * it contains only valid UTF-8 bytes/byte sequences.
 *
 * Raises EncodingError on failure.
 */
static VALUE pvt_bson_encode_to_utf8(VALUE string) {
  VALUE existing_encoding_name;
  VALUE encoding;
  VALUE utf8_string;
  const char *str;
  int32_t length;
  
  existing_encoding_name = rb_funcall(
    rb_funcall(string, rb_intern("encoding"), 0),
    rb_intern("name"), 0);
  
  if (strcmp(RSTRING_PTR(existing_encoding_name), "UTF-8") == 0) {
    utf8_string = string;
  
    str = RSTRING_PTR(utf8_string);
    length = RSTRING_LEN(utf8_string);
    
    rb_bson_utf8_validate(str, length, true, "String");
  } else {
    encoding = rb_enc_str_new_cstr("UTF-8", rb_utf8_encoding());
    utf8_string = rb_funcall(string, rb_intern("encode"), 1, encoding);
    RB_GC_GUARD(encoding);
  }
  
  return utf8_string;
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_put_string(VALUE self, VALUE string)
{
  VALUE utf8_string;
  const char *str;
  int32_t length;
  
  utf8_string = pvt_bson_encode_to_utf8(string);
  /* At this point utf8_string contains valid utf-8 byte sequences only */
  
  str = RSTRING_PTR(utf8_string);
  length = RSTRING_LEN(utf8_string);

  RB_GC_GUARD(utf8_string);
  
  return pvt_bson_byte_buffer_put_binary_string(self, str, length);
}

/**
 * Writes a string (which may form part of a BSON object) to the byte buffer.
 *
 * Note: the string may not contain null bytes, and must be null-terminated.
 * length is the number of bytes to write and does not include the null
 * terminator.
 */
VALUE pvt_bson_byte_buffer_put_bson_partial_string(VALUE self, const char *str, int32_t length)
{
  byte_buffer_t *b;
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  pvt_put_cstring(b, str, length, "String");
  return self;
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_put_cstring(VALUE self, VALUE obj)
{
  VALUE string;
  const char *str;
  int32_t length;

  switch (TYPE(obj)) {
  case T_STRING:
    string = pvt_bson_encode_to_utf8(obj);
    break;
  case T_SYMBOL:
    string = rb_sym2str(obj);
    break;
  case T_FIXNUM:
    string = rb_fix2str(obj, 10);
    break;
  default:
    rb_raise(rb_eTypeError, "Invalid type for put_cstring");
  }
  
  str = RSTRING_PTR(string);
  length = RSTRING_LEN(string);
  RB_GC_GUARD(string);
  return pvt_bson_byte_buffer_put_bson_partial_string(self, str, length);
}

/**
 * Writes a string (which may form part of a BSON object) to the byte buffer.
 *
 * Note: the string may not contain null bytes, and must be null-terminated.
 * length is the number of bytes to write and does not include the null
 * terminator.
 *
 * data_type is the type of data being written, e.g. "String" or "Key".
 */
void pvt_put_cstring(byte_buffer_t *b, const char *str, int32_t length, const char *data_type)
{
  int bytes_to_write;
  rb_bson_utf8_validate(str, length, false, data_type);
  bytes_to_write = length + 1;
  ENSURE_BSON_WRITE(b, bytes_to_write);
  memcpy(WRITE_PTR(b), str, bytes_to_write);
  b->write_position += bytes_to_write;
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_put_symbol(VALUE self, VALUE symbol)
{
  VALUE symbol_str = rb_sym_to_s(symbol);
  const char *str = RSTRING_PTR(symbol_str);
  const int32_t length = RSTRING_LEN(symbol_str);

  RB_GC_GUARD(symbol_str);
  return pvt_bson_byte_buffer_put_binary_string(self, str, length);
}

/**
 * Write a hash key to the byte buffer, validating it if requested
 */
void pvt_put_bson_key(byte_buffer_t *b, VALUE string, VALUE validating_keys){
  char *c_str = RSTRING_PTR(string);
  size_t length = RSTRING_LEN(string);
  
  if (RTEST(validating_keys)) {
    if (length > 0 && (c_str[0] == '$' || memchr(c_str, '.', length))) {
      rb_exc_raise(rb_funcall(rb_bson_illegal_key, rb_intern("new"), 1, string));
    }
  }

  pvt_put_cstring(b, c_str, length, "Key");
}

void pvt_replace_int32(byte_buffer_t *b, int32_t position, int32_t newval)
{
  const int32_t i32 = BSON_UINT32_TO_LE(newval);
  memcpy(READ_PTR(b) + position, &i32, 4);
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_replace_int32(VALUE self, VALUE position, VALUE newval)
{
  byte_buffer_t *b;
  long _position;
  
  _position = NUM2LONG(position);
  if (_position < 0) {
    rb_raise(rb_eArgError, "Position given to replace_int32 cannot be negative: %ld", _position);
  }
  
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  
  if (b->write_position < 4) {
    rb_raise(rb_eArgError, "Buffer does not have enough data to use replace_int32");
  }
  
  if ((size_t) _position > b->write_position - 4) {
    rb_raise(rb_eArgError, "Position given to replace_int32 is out of bounds: %ld", _position);
  }

  pvt_replace_int32(b, _position, NUM2LONG(newval));

  return self;
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_put_int32(VALUE self, VALUE i)
{
  byte_buffer_t *b;
  const int32_t i32 = NUM2INT(i);

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  pvt_put_int32(b, i32);
  return self;
}

void pvt_put_int32(byte_buffer_t *b, const int32_t i)
{
  const int32_t i32 = BSON_UINT32_TO_LE(i);
  ENSURE_BSON_WRITE(b, 4);
  memcpy(WRITE_PTR(b), &i32, 4);
  b->write_position += 4;
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_put_uint32(VALUE self, VALUE i)
{
  byte_buffer_t *b;
  int64_t temp;
  uint32_t i32;

  if (RB_TYPE_P(i, T_FLOAT)) {
    rb_raise(rb_eArgError, "put_uint32: incorrect type: float, expected: integer");
  }

  temp = NUM2LL(i);
  if (temp < 0 || temp > UINT32_MAX) {
    rb_raise(rb_eRangeError, "Number %lld is out of range [0, 2^32)", (long long)temp);
  }

  i32 = NUM2UINT(i);

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  pvt_put_uint32(b, i32);
  return self;
}

void pvt_put_uint32(byte_buffer_t *b, const uint32_t i)
{
  const uint32_t i32 = BSON_UINT32_TO_LE(i);
  ENSURE_BSON_WRITE(b, 4);
  memcpy(WRITE_PTR(b), &i32, 4);
  b->write_position += 4;
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_put_int64(VALUE self, VALUE i)
{
  byte_buffer_t *b;
  const int64_t i64 = NUM2LL(i);

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  pvt_put_int64(b, i64);

  return self;
}

void pvt_put_int64(byte_buffer_t *b, const int64_t i)
{
  const int64_t i64 = BSON_UINT64_TO_LE(i);

  ENSURE_BSON_WRITE(b, 8);
  memcpy(WRITE_PTR(b), &i64, 8);
  b->write_position += 8;
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_put_double(VALUE self, VALUE f)
{
  byte_buffer_t *b;
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  pvt_put_double(b, NUM2DBL(f));

  return self;
}

void pvt_put_double(byte_buffer_t *b, double f)
{
  const double d = BSON_DOUBLE_TO_LE(f);
  ENSURE_BSON_WRITE(b, 8);
  memcpy(WRITE_PTR(b), &d, 8);
  b->write_position += 8;
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_put_decimal128(VALUE self, VALUE low, VALUE high)
{
  byte_buffer_t *b;
  const int64_t low64 = BSON_UINT64_TO_LE(NUM2ULL(low));
  const int64_t high64 = BSON_UINT64_TO_LE(NUM2ULL(high));

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  ENSURE_BSON_WRITE(b, 16);
  memcpy(WRITE_PTR(b), &low64, 8);
  b->write_position += 8;

  memcpy(WRITE_PTR(b), &high64, 8);
  b->write_position += 8;

  return self;
}

static int put_hash_callback(VALUE key, VALUE val, VALUE context){
  VALUE buffer = ((put_hash_context*)context)->buffer;
  VALUE validating_keys = ((put_hash_context*)context)->validating_keys;
  byte_buffer_t *b = ((put_hash_context*)context)->b;
  VALUE key_str;

  pvt_put_type_byte(b, val);

  switch(TYPE(key)){
    case T_STRING:
      pvt_put_bson_key(b, key, validating_keys);
      break;
    case T_SYMBOL:
      key_str = rb_sym_to_s(key);
      RB_GC_GUARD(key_str);
      pvt_put_bson_key(b, key_str, validating_keys);
      break;
    default:
      rb_bson_byte_buffer_put_cstring(buffer, rb_funcall(key, rb_intern("to_bson_key"), 1, validating_keys));
  }

  pvt_put_field(b, buffer, val, validating_keys);
  return ST_CONTINUE;
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_put_hash(VALUE self, VALUE hash, VALUE validating_keys){
  byte_buffer_t *b = NULL;
  put_hash_context context = { NULL };
  size_t position = 0;
  size_t new_position = 0;
  int32_t new_length = 0;

  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  Check_Type(hash, T_HASH);

  position = READ_SIZE(b);

  /* insert length placeholder */
  pvt_put_int32(b, 0);
  context.buffer = self;
  context.validating_keys = validating_keys;
  context.b = b;

  rb_hash_foreach(hash, put_hash_callback, (VALUE)&context);
  pvt_put_byte(b, 0);

  /* update length placeholder with actual value */
  new_position = READ_SIZE(b);
  new_length = new_position - position;
  pvt_replace_int32(b, position, new_length);

  return self;
}

static const char *index_strings[] = {
   "0",   "1",   "2",   "3",   "4",   "5",   "6",   "7",   "8",   "9",   "10",
   "11",  "12",  "13",  "14",  "15",  "16",  "17",  "18",  "19",  "20",  "21",
   "22",  "23",  "24",  "25",  "26",  "27",  "28",  "29",  "30",  "31",  "32",
   "33",  "34",  "35",  "36",  "37",  "38",  "39",  "40",  "41",  "42",  "43",
   "44",  "45",  "46",  "47",  "48",  "49",  "50",  "51",  "52",  "53",  "54",
   "55",  "56",  "57",  "58",  "59",  "60",  "61",  "62",  "63",  "64",  "65",
   "66",  "67",  "68",  "69",  "70",  "71",  "72",  "73",  "74",  "75",  "76",
   "77",  "78",  "79",  "80",  "81",  "82",  "83",  "84",  "85",  "86",  "87",
   "88",  "89",  "90",  "91",  "92",  "93",  "94",  "95",  "96",  "97",  "98",
   "99",  "100", "101", "102", "103", "104", "105", "106", "107", "108", "109",
   "110", "111", "112", "113", "114", "115", "116", "117", "118", "119", "120",
   "121", "122", "123", "124", "125", "126", "127", "128", "129", "130", "131",
   "132", "133", "134", "135", "136", "137", "138", "139", "140", "141", "142",
   "143", "144", "145", "146", "147", "148", "149", "150", "151", "152", "153",
   "154", "155", "156", "157", "158", "159", "160", "161", "162", "163", "164",
   "165", "166", "167", "168", "169", "170", "171", "172", "173", "174", "175",
   "176", "177", "178", "179", "180", "181", "182", "183", "184", "185", "186",
   "187", "188", "189", "190", "191", "192", "193", "194", "195", "196", "197",
   "198", "199", "200", "201", "202", "203", "204", "205", "206", "207", "208",
   "209", "210", "211", "212", "213", "214", "215", "216", "217", "218", "219",
   "220", "221", "222", "223", "224", "225", "226", "227", "228", "229", "230",
   "231", "232", "233", "234", "235", "236", "237", "238", "239", "240", "241",
   "242", "243", "244", "245", "246", "247", "248", "249", "250", "251", "252",
   "253", "254", "255", "256", "257", "258", "259", "260", "261", "262", "263",
   "264", "265", "266", "267", "268", "269", "270", "271", "272", "273", "274",
   "275", "276", "277", "278", "279", "280", "281", "282", "283", "284", "285",
   "286", "287", "288", "289", "290", "291", "292", "293", "294", "295", "296",
   "297", "298", "299", "300", "301", "302", "303", "304", "305", "306", "307",
   "308", "309", "310", "311", "312", "313", "314", "315", "316", "317", "318",
   "319", "320", "321", "322", "323", "324", "325", "326", "327", "328", "329",
   "330", "331", "332", "333", "334", "335", "336", "337", "338", "339", "340",
   "341", "342", "343", "344", "345", "346", "347", "348", "349", "350", "351",
   "352", "353", "354", "355", "356", "357", "358", "359", "360", "361", "362",
   "363", "364", "365", "366", "367", "368", "369", "370", "371", "372", "373",
   "374", "375", "376", "377", "378", "379", "380", "381", "382", "383", "384",
   "385", "386", "387", "388", "389", "390", "391", "392", "393", "394", "395",
   "396", "397", "398", "399", "400", "401", "402", "403", "404", "405", "406",
   "407", "408", "409", "410", "411", "412", "413", "414", "415", "416", "417",
   "418", "419", "420", "421", "422", "423", "424", "425", "426", "427", "428",
   "429", "430", "431", "432", "433", "434", "435", "436", "437", "438", "439",
   "440", "441", "442", "443", "444", "445", "446", "447", "448", "449", "450",
   "451", "452", "453", "454", "455", "456", "457", "458", "459", "460", "461",
   "462", "463", "464", "465", "466", "467", "468", "469", "470", "471", "472",
   "473", "474", "475", "476", "477", "478", "479", "480", "481", "482", "483",
   "484", "485", "486", "487", "488", "489", "490", "491", "492", "493", "494",
   "495", "496", "497", "498", "499", "500", "501", "502", "503", "504", "505",
   "506", "507", "508", "509", "510", "511", "512", "513", "514", "515", "516",
   "517", "518", "519", "520", "521", "522", "523", "524", "525", "526", "527",
   "528", "529", "530", "531", "532", "533", "534", "535", "536", "537", "538",
   "539", "540", "541", "542", "543", "544", "545", "546", "547", "548", "549",
   "550", "551", "552", "553", "554", "555", "556", "557", "558", "559", "560",
   "561", "562", "563", "564", "565", "566", "567", "568", "569", "570", "571",
   "572", "573", "574", "575", "576", "577", "578", "579", "580", "581", "582",
   "583", "584", "585", "586", "587", "588", "589", "590", "591", "592", "593",
   "594", "595", "596", "597", "598", "599", "600", "601", "602", "603", "604",
   "605", "606", "607", "608", "609", "610", "611", "612", "613", "614", "615",
   "616", "617", "618", "619", "620", "621", "622", "623", "624", "625", "626",
   "627", "628", "629", "630", "631", "632", "633", "634", "635", "636", "637",
   "638", "639", "640", "641", "642", "643", "644", "645", "646", "647", "648",
   "649", "650", "651", "652", "653", "654", "655", "656", "657", "658", "659",
   "660", "661", "662", "663", "664", "665", "666", "667", "668", "669", "670",
   "671", "672", "673", "674", "675", "676", "677", "678", "679", "680", "681",
   "682", "683", "684", "685", "686", "687", "688", "689", "690", "691", "692",
   "693", "694", "695", "696", "697", "698", "699", "700", "701", "702", "703",
   "704", "705", "706", "707", "708", "709", "710", "711", "712", "713", "714",
   "715", "716", "717", "718", "719", "720", "721", "722", "723", "724", "725",
   "726", "727", "728", "729", "730", "731", "732", "733", "734", "735", "736",
   "737", "738", "739", "740", "741", "742", "743", "744", "745", "746", "747",
   "748", "749", "750", "751", "752", "753", "754", "755", "756", "757", "758",
   "759", "760", "761", "762", "763", "764", "765", "766", "767", "768", "769",
   "770", "771", "772", "773", "774", "775", "776", "777", "778", "779", "780",
   "781", "782", "783", "784", "785", "786", "787", "788", "789", "790", "791",
   "792", "793", "794", "795", "796", "797", "798", "799", "800", "801", "802",
   "803", "804", "805", "806", "807", "808", "809", "810", "811", "812", "813",
   "814", "815", "816", "817", "818", "819", "820", "821", "822", "823", "824",
   "825", "826", "827", "828", "829", "830", "831", "832", "833", "834", "835",
   "836", "837", "838", "839", "840", "841", "842", "843", "844", "845", "846",
   "847", "848", "849", "850", "851", "852", "853", "854", "855", "856", "857",
   "858", "859", "860", "861", "862", "863", "864", "865", "866", "867", "868",
   "869", "870", "871", "872", "873", "874", "875", "876", "877", "878", "879",
   "880", "881", "882", "883", "884", "885", "886", "887", "888", "889", "890",
   "891", "892", "893", "894", "895", "896", "897", "898", "899", "900", "901",
   "902", "903", "904", "905", "906", "907", "908", "909", "910", "911", "912",
   "913", "914", "915", "916", "917", "918", "919", "920", "921", "922", "923",
   "924", "925", "926", "927", "928", "929", "930", "931", "932", "933", "934",
   "935", "936", "937", "938", "939", "940", "941", "942", "943", "944", "945",
   "946", "947", "948", "949", "950", "951", "952", "953", "954", "955", "956",
   "957", "958", "959", "960", "961", "962", "963", "964", "965", "966", "967",
   "968", "969", "970", "971", "972", "973", "974", "975", "976", "977", "978",
   "979", "980", "981", "982", "983", "984", "985", "986", "987", "988", "989",
   "990", "991", "992", "993", "994", "995", "996", "997", "998", "999"};

/**
 * Writes an array index to the byte buffer.
 */
void pvt_put_array_index(byte_buffer_t *b, int32_t index)
{
  char buffer[16];
  const char *c_str = NULL;
  size_t length;

  if (index < 1000) {
    c_str = index_strings[index];
  } else {
    c_str = buffer;
    snprintf(buffer, sizeof(buffer), "%d", index);
  }
  length = strlen(c_str) + 1;
  ENSURE_BSON_WRITE(b, length);
  memcpy(WRITE_PTR(b), c_str, length);
  b->write_position += length;
}

/* The docstring is in init.c. */
VALUE rb_bson_byte_buffer_put_array(VALUE self, VALUE array, VALUE validating_keys){
  byte_buffer_t *b = NULL;
  size_t new_position = 0;
  int32_t new_length = 0;
  size_t position = 0;
  VALUE *array_element = NULL;
  TypedData_Get_Struct(self, byte_buffer_t, &rb_byte_buffer_data_type, b);
  Check_Type(array, T_ARRAY);

  position = READ_SIZE(b);
  /* insert length placeholder */
  pvt_put_int32(b, 0);

  array_element = RARRAY_PTR(array);

  for(int32_t index=0; index < RARRAY_LEN(array); index++, array_element++){
    pvt_put_type_byte(b, *array_element);
    pvt_put_array_index(b, index);
    pvt_put_field(b, self, *array_element, validating_keys);
  }
  pvt_put_byte(b, 0);

  /* update length placeholder */
  new_position = READ_SIZE(b);
  new_length = new_position - position;
  pvt_replace_int32(b, position, new_length);

  return self;
}
