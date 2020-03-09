/*
 * Copyright (C) 2015-2020 MongoDB Inc.
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

#include <string.h>
#include <stdint.h>
#include "bson-endian.h"

/*
 *--------------------------------------------------------------------------
 *
 * __bson_uint16_swap_slow --
 *
 *       Fallback endianness conversion for 16-bit integers.
 *
 * Returns:
 *       The endian swapped version.
 *
 * Side effects:
 *       None.
 *
 *--------------------------------------------------------------------------
 */
uint16_t __bson_uint16_swap_slow(uint16_t v)
{
   return ((v & 0x00FF) << 8) |
          ((v & 0xFF00) >> 8);
}

/*
 *--------------------------------------------------------------------------
 *
 * __bson_uint32_swap_slow --
 *
 *       Fallback endianness conversion for 32-bit integers.
 *
 * Returns:
 *       The endian swapped version.
 *
 * Side effects:
 *       None.
 *
 *--------------------------------------------------------------------------
 */
uint32_t __bson_uint32_swap_slow(uint32_t v)
{
   return ((v & 0x000000FFU) << 24) |
          ((v & 0x0000FF00U) <<  8) |
          ((v & 0x00FF0000U) >>  8) |
          ((v & 0xFF000000U) >> 24);
}


/*
 *--------------------------------------------------------------------------
 *
 * __bson_uint64_swap_slow --
 *
 *       Fallback endianness conversion for 64-bit integers.
 *
 * Returns:
 *       The endian swapped version.
 *
 * Side effects:
 *       None.
 *
 *--------------------------------------------------------------------------
 */
uint64_t __bson_uint64_swap_slow(uint64_t v)
{
   return ((v & 0x00000000000000FFULL) << 56) |
          ((v & 0x000000000000FF00ULL) << 40) |
          ((v & 0x0000000000FF0000ULL) << 24) |
          ((v & 0x00000000FF000000ULL) <<  8) |
          ((v & 0x000000FF00000000ULL) >>  8) |
          ((v & 0x0000FF0000000000ULL) >> 24) |
          ((v & 0x00FF000000000000ULL) >> 40) |
          ((v & 0xFF00000000000000ULL) >> 56);
}

/*
 *--------------------------------------------------------------------------
 *
 * __bson_double_swap_slow --
 *
 *       Fallback endianness conversion for double floating point.
 *
 * Returns:
 *       The endian swapped version.
 *
 * Side effects:
 *       None.
 *
 *--------------------------------------------------------------------------
 */
double __bson_double_swap_slow(double v)
{
   uint64_t uv;

   memcpy(&uv, &v, sizeof(v));
   uv = BSON_UINT64_SWAP_LE_BE(uv);
   memcpy(&v, &uv, sizeof(v));

   return v;
}
