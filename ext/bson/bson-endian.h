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

#if (defined(_WIN16) || defined(_WIN32) || defined(_WIN64)) && !defined(__WINDOWS__)

# define __WINDOWS__
# include <winsock2.h>
#else
# include <arpa/inet.h>
# include <sys/types.h>
#endif

#define BSON_BIG_ENDIAN    4321
#define BSON_LITTLE_ENDIAN 1234

#if defined(__sun)
# include <sys/byteorder.h>
# if defined(_LITTLE_ENDIAN)
#  define BSON_BYTE_ORDER 1234
# else
#  define BSON_BYTE_ORDER 4321
# endif
#endif

/* See a similar check in ruby's sha2.h */
# ifndef BSON_BYTE_ORDER
#  ifdef WORDS_BIGENDIAN
#   define BSON_BYTE_ORDER	BSON_BIG_ENDIAN
#  else
#   define BSON_BYTE_ORDER	BSON_LITTLE_ENDIAN
#  endif
# endif /* BSON_BYTE_ORDER */

#if defined(__sun)
# define BSON_UINT16_SWAP_LE_BE(v) __bson_uint16_swap_slow((uint16_t)v)
# define BSON_UINT32_SWAP_LE_BE(v) __bson_uint32_swap_slow((uint32_t)v)
# define BSON_UINT64_SWAP_LE_BE(v) __bson_uint64_swap_slow((uint64_t)v)
#elif defined(__clang__) && defined(__clang_major__) && defined(__clang_minor__) && \
  (__clang_major__ >= 3) && (__clang_minor__ >= 1)
# if __has_builtin(__builtin_bswap16)
#  define BSON_UINT16_SWAP_LE_BE(v) __builtin_bswap16(v)
# endif
# if __has_builtin(__builtin_bswap32)
#  define BSON_UINT32_SWAP_LE_BE(v) __builtin_bswap32(v)
# endif
# if __has_builtin(__builtin_bswap64)
#  define BSON_UINT64_SWAP_LE_BE(v) __builtin_bswap64(v)
# endif
#elif defined(__GNUC__) && (__GNUC__ >= 4)
# if __GNUC__ > 4 || (defined (__GNUC_MINOR__) && __GNUC_MINOR__ >= 3)
#  define BSON_UINT32_SWAP_LE_BE(v) __builtin_bswap32 ((uint32_t)v)
#  define BSON_UINT64_SWAP_LE_BE(v) __builtin_bswap64 ((uint64_t)v)
# endif
#endif

#ifndef BSON_UINT16_SWAP_LE_BE
# define BSON_UINT16_SWAP_LE_BE(v) __bson_uint16_swap_slow((uint16_t)v)
#endif

#ifndef BSON_UINT32_SWAP_LE_BE
# define BSON_UINT32_SWAP_LE_BE(v) __bson_uint32_swap_slow((uint32_t)v)
#endif

#ifndef BSON_UINT64_SWAP_LE_BE
# define BSON_UINT64_SWAP_LE_BE(v) __bson_uint64_swap_slow((uint64_t)v)
#endif

#if BSON_BYTE_ORDER == BSON_LITTLE_ENDIAN
# define BSON_UINT16_TO_BE(v)    BSON_UINT16_SWAP_LE_BE(v)
# define BSON_UINT32_FROM_LE(v)  ((uint32_t)v)
# define BSON_UINT32_TO_LE(v)    ((uint32_t)v)
# define BSON_UINT32_FROM_BE(v)  BSON_UINT32_SWAP_LE_BE(v)
# define BSON_UINT32_TO_BE(v)    BSON_UINT32_SWAP_LE_BE(v)
# define BSON_UINT64_FROM_LE(v)  ((uint64_t)v)
# define BSON_UINT64_TO_LE(v)    ((uint64_t)v)
# define BSON_UINT64_FROM_BE(v)  BSON_UINT64_SWAP_LE_BE(v)
# define BSON_UINT64_TO_BE(v)    BSON_UINT64_SWAP_LE_BE(v)
# define BSON_DOUBLE_FROM_LE(v)  ((double)v)
# define BSON_DOUBLE_TO_LE(v)    ((double)v)
#elif BSON_BYTE_ORDER == BSON_BIG_ENDIAN
# define BSON_UINT16_TO_BE(v)    ((uint16_t)v)
# define BSON_UINT32_FROM_LE(v)  BSON_UINT32_SWAP_LE_BE(v)
# define BSON_UINT32_TO_LE(v)    BSON_UINT32_SWAP_LE_BE(v)
# define BSON_UINT32_FROM_BE(v)  ((uint32_t)v)
# define BSON_UINT32_TO_BE(v)    ((uint32_t)v)
# define BSON_UINT64_FROM_LE(v)  BSON_UINT64_SWAP_LE_BE(v)
# define BSON_UINT64_TO_LE(v)    BSON_UINT64_SWAP_LE_BE(v)
# define BSON_UINT64_FROM_BE(v)  ((uint64_t)v)
# define BSON_UINT64_TO_BE(v)    ((uint64_t)v)
# define BSON_DOUBLE_FROM_LE(v)  (__bson_double_swap_slow(v))
# define BSON_DOUBLE_TO_LE(v)    (__bson_double_swap_slow(v))
#else
# error "The endianness of target architecture is unknown."
#endif

uint16_t __bson_uint16_swap_slow(uint16_t v);
uint32_t __bson_uint32_swap_slow(uint32_t v);
uint64_t __bson_uint64_swap_slow(uint64_t v);
double __bson_double_swap_slow(double v);
