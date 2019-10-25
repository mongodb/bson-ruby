#include <ruby.h>
#include <ruby/encoding.h>
#include <stdbool.h>
#include <unistd.h>
#include <assert.h>
#include "bson-native.h"

/**
 * Taken from libbson.
 */

#define BSON_ASSERT assert
#define BSON_INLINE


/*
 *--------------------------------------------------------------------------
 *
 * _bson_utf8_get_sequence --
 *
 *       Determine the sequence length of the first UTF-8 character in
 *       @utf8. The sequence length is stored in @seq_length and the mask
 *       for the first character is stored in @first_mask.
 *
 * Returns:
 *       None.
 *
 * Side effects:
 *       @seq_length is set.
 *       @first_mask is set.
 *
 *--------------------------------------------------------------------------
 */

static BSON_INLINE void
_bson_utf8_get_sequence (const char *utf8,    /* IN */
                         uint8_t *seq_length, /* OUT */
                         uint8_t *first_mask) /* OUT */
{
   unsigned char c = *(const unsigned char *) utf8;
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
   } else {
      n = 0;
      m = 0;
   }

   *seq_length = n;
   *first_mask = m;
}


/*
 *--------------------------------------------------------------------------
 *
 * bson_utf8_validate --
 *
 *       Validates that @utf8 is a valid UTF-8 string. Note that we only
 *       support UTF-8 characters which have sequence length less than or equal
 *       to 4 bytes (RFC 3629).
 *
 *       If @allow_null is true, then \0 is allowed within @utf8_len bytes
 *       of @utf8.  Generally, this is bad practice since the main point of
 *       UTF-8 strings is that they can be used with strlen() and friends.
 *       However, some languages such as Python can send UTF-8 encoded
 *       strings with NUL's in them.
 *
 * Parameters:
 *       @utf8: A UTF-8 encoded string.
 *       @utf8_len: The length of @utf8 in bytes.
 *       @allow_null: If \0 is allowed within @utf8, exclusing trailing \0.
 *       @data_type: The data type being serialized.
 *
 * Returns:
 *       true if @utf8 is valid UTF-8. otherwise false.
 *
 * Side effects:
 *       None.
 *
 *--------------------------------------------------------------------------
 */

void
rb_bson_utf8_validate (const char *utf8, /* IN */
                    size_t utf8_len,  /* IN */
                    bool allow_null, /* IN */
                    const char *data_type)  /* IN */
{
   uint32_t c;
   uint8_t first_mask;
   uint8_t seq_length;
   unsigned i;
   unsigned j;
   bool not_shortest_form;

   BSON_ASSERT (utf8);

   for (i = 0; i < utf8_len; i += seq_length) {
      _bson_utf8_get_sequence (&utf8[i], &seq_length, &first_mask);

      /*
       * Ensure we have a valid multi-byte sequence length.
       */
      if (!seq_length) {
         rb_raise(rb_eEncodingError, "%s %s is not valid UTF-8: bogus initial bits", data_type, utf8);
      }

      /*
       * Ensure we have enough bytes left.
       */
      if ((utf8_len - i) < seq_length) {
         rb_raise(rb_eEncodingError, "%s %s is not valid UTF-8: truncated multi-byte sequence", data_type, utf8);
      }

      /*
       * Also calculate the next char as a unichar so we can
       * check code ranges for non-shortest form.
       */
      c = utf8[i] & first_mask;

      /*
       * Check the high-bits for each additional sequence byte.
       */
      for (j = i + 1; j < (i + seq_length); j++) {
         c = (c << 6) | (utf8[j] & 0x3F);
         if ((utf8[j] & 0xC0) != 0x80) {
            rb_raise(rb_eEncodingError, "%s %s is not valid UTF-8: bogus high bits for continuation byte", data_type, utf8);
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
               rb_raise(rb_eArgError, "%s %s contains null bytes", data_type, utf8);
            }
         }
      }

      /*
       * Code point won't fit in utf-16, not allowed.
       */
      if (c > 0x0010FFFF) {
         rb_raise(rb_eEncodingError, "%s %s is not valid UTF-8: code point %"PRIu32" does not fit in UTF-16", data_type, utf8, c);
      }

      /*
       * Byte is in reserved range for UTF-16 high-marks
       * for surrogate pairs.
       */
      if ((c & 0xFFFFF800) == 0xD800) {
         rb_raise(rb_eEncodingError, "%s %s is not valid UTF-8: byte is in surrogate pair reserved range", data_type, utf8);
      }

      /*
       * Check non-shortest form unicode.
       */
      not_shortest_form = false;
      switch (seq_length) {
      case 1:
         if (c <= 0x007F) {
            continue;
         }
         not_shortest_form = true;

      case 2:
         if ((c >= 0x0080) && (c <= 0x07FF)) {
            continue;
         } else if (c == 0) {
            /* Two-byte representation for NULL. */
            if (!allow_null) {
               rb_raise(rb_eArgError, "%s %s contains null bytes", data_type, utf8);
            }
            continue;
         }
         not_shortest_form = true;

      case 3:
         if (((c >= 0x0800) && (c <= 0x0FFF)) ||
             ((c >= 0x1000) && (c <= 0xFFFF))) {
            continue;
         }
         not_shortest_form = true;

      case 4:
         if (((c >= 0x10000) && (c <= 0x3FFFF)) ||
             ((c >= 0x40000) && (c <= 0xFFFFF)) ||
             ((c >= 0x100000) && (c <= 0x10FFFF))) {
            continue;
         }
         not_shortest_form = true;

      default:
         not_shortest_form = true;
      }
      
      if (not_shortest_form) {
        rb_raise(rb_eEncodingError, "%s %s is not valid UTF-8: not in shortest form", data_type, utf8);
      }
   }
}
