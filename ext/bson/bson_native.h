#include <stdbool.h>
#include <unistd.h>

void
rb_bson_utf8_validate (const char *utf8, /* IN */
                    size_t utf8_len,  /* IN */
                    bool allow_null);  /* IN */
