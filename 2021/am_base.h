#ifndef AM_BASE_H
#define AM_BASE_H

#if __STDC_VERSION__ < 201112L
# error "C11 or greater required."
#endif

// context
// https://sourceforge.net/p/predef/wiki/Home/
#if defined(__clang__)
# define COMPILER_CLANG 1
#elif defined (__GNUC__)
# define COMPILER_GCC 1
#else
# error "Unsupported compiler."
#endif

#if !defined(COMPILER_CLANG)
# define COMPILER_CLANG 0
#endif
#if !defined(COMPILER_GCC)
# define COMPILER_GCC 0
#endif

#if defined (__linux__)
# define OPERATING_SYSTEM_LINUX 1
#elif defined(_WIN32)
# define OPERATING_SYSTEM_WINDOWS 1
#else
# error "Unsupported OS."
#endif

#if !defined(OPERATING_SYSTEM_LINUX)
# define OPERATING_SYSTEM_LINUX 0
#endif
#if !defined(OPERATING_SYSTEM_WINDOWS)
# define OPERATING_SYSTEM_WINDOWS 0
#endif

// compiler builtins
#if COMPILER_CLANG || COMPILER_GCC
# ifndef __has_builtin
#  define __has_builtin(x) 0
# endif
#endif

#define IMPLEMENTATION_UNSIGNED_CHAR (CHAR_MIN == 0)

// freestanding headers
#include <float.h>
#include <limits.h>
#include <stdalign.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdnoreturn.h>

// preprocessor improvement
#define AM__STRINGIFY(S) #S
#define AM__GLUE(A, B) A##B
#define AM_STRINGIFY(S) AM__STRINGIFY(S)
#define AM_GLUE(A, B) AM__GLUE((A), (B))

// assert
#define static_assert(expr) _Static_assert((expr), "")

#if !defined(AM_ENABLE_ASSERT)
# define AM_ENABLE_ASSERT 0
#endif

#if AM_ENABLE_ASSERT
# if !defined(AM_ASSERT_FAIL)
#  if __has_builtin(__builtin_trap)
#   define AM_ASSERT_FAIL(expr, file, line, func) __builtin_trap()
#  else
#   error "Must define implementation of AM_ASSERT_FAIL(expr, file, line, func)."
#  endif
# endif
# define assert(x) ((void)((x) || (AM_ASSERT_FAIL(AM_STRINGIFY(x), __FILE__, __LINE__, __func__),0)))
#else
# define assert(c) ((void)0)
#endif

#define AM_UNREACHABLE assert(false && "Unreachable code reached")

// utility macros
#define ALIGN_UP_POW_2(x, p) (((x) + (p) - 1) & ~((p) - (1)))
#define ALIGN_DOWN_POW_2(x, p) ((x) & ~((p) - 1))
#define ARRAY_COUNT(a) (sizeof(a)/sizeof(*(a)))
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MAX(a, b) (((a) > (b)) ? (a) : (b))
#define CLAMP(a, x, b) (((x) < (a)) ? (a) : (((b) < (x)) ? (b) : (x)))
#define CLAMP_TOP(a, b) MIN((a), (b))
#define CLAMP_BOT(a, b) MAX((a), (b))
#define UNUSED(p) (void)(p)

// basic types
typedef int8_t   s8;
typedef int16_t  s16;
typedef int32_t  s32;
typedef int64_t  s64;
typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef size_t   usz;
typedef float    f32;
typedef double   f64;

#define global        static
#define local_persist static
#define internal      static

// sanity checks
static_assert(CHAR_BIT == 8);

#endif // AM_BASE_H
