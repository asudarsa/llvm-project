// RUN: %clang_cc1 -std=c11 -Wgnu-folding-constant -fsyntax-only -verify %s
// RUN: %clang_cc1 -fms-compatibility -Wgnu-folding-constant -DMS -fsyntax-only -verify=expected,ms %s
// RUN: %clang_cc1 -std=c99 -fms-compatibility -Wgnu-folding-constant -DMS -fsyntax-only -verify=expected,ms %s
// RUN: %clang_cc1 -std=c99 -pedantic -Wgnu-folding-constant -fsyntax-only -verify=expected,ext %s
// RUN: %clang_cc1 -xc++ -std=c++11 -pedantic -fsyntax-only -verify=expected,ext,cxx %s

_Static_assert("foo", "string is nonzero"); // ext-warning {{'_Static_assert' is a C11 extension}}
#ifndef __cplusplus
// expected-warning@-2 {{expression is not an integer constant expression; folding it to a constant is a GNU extension}}
#endif

_Static_assert(1, "1 is nonzero"); // ext-warning {{'_Static_assert' is a C11 extension}}
_Static_assert(0, "0 is nonzero"); // expected-error {{static assertion failed: 0 is nonzero}} \
                                   // ext-warning {{'_Static_assert' is a C11 extension}}

#ifdef MS
static_assert(1, "1 is nonzero");
#endif

void foo(void) {
  _Static_assert(1, "1 is nonzero"); // ext-warning {{'_Static_assert' is a C11 extension}}
  _Static_assert(0, "0 is nonzero"); // expected-error {{static assertion failed: 0 is nonzero}} \
                                     // ext-warning {{'_Static_assert' is a C11 extension}}
#ifdef MS
  static_assert(1, "1 is nonzero");
#endif
}

_Static_assert(1, invalid); // ext-warning {{'_Static_assert' is a C11 extension}}
#ifndef __cplusplus
// expected-error@-2 {{expected string literal for diagnostic message in static_assert}}
#endif
// cxx-error@-4 {{use of undeclared identifier 'invalid'}}
// cxx-warning@-5 {{'static_assert' with a user-generated message is a C++26 extension}}

struct A {
  int a;
  _Static_assert(1, "1 is nonzero"); // ext-warning {{'_Static_assert' is a C11 extension}}
  _Static_assert(0, "0 is nonzero"); // expected-error {{static assertion failed: 0 is nonzero}} \
                                     // ext-warning {{'_Static_assert' is a C11 extension}}
#ifdef MS
  static_assert(1, "1 is nonzero");
#endif
};

#ifdef __cplusplus
#define ASSERT_IS_TYPE(T) __is_same(T, T)
#else
#define ASSERT_IS_TYPE(T) __builtin_types_compatible_p(T, T)
#endif

#define UNION(T1, T2) union { \
    __typeof__(T1) one; \
    __typeof__(T2) two; \
    _Static_assert(ASSERT_IS_TYPE(T1), "T1 is not a type"); \
    _Static_assert(ASSERT_IS_TYPE(T2), "T2 is not a type"); \
    _Static_assert(sizeof(T1) == sizeof(T2), "type size mismatch"); \
  }

typedef UNION(unsigned, struct A) U1; // ext-warning 3 {{'_Static_assert' is a C11 extension}}
UNION(char[2], short) u2 = { .one = { 'a', 'b' } }; // ext-warning 3 {{'_Static_assert' is a C11 extension}} cxx-warning {{designated initializers are a C++20 extension}}
typedef UNION(char, short) U3; // expected-error {{static assertion failed due to requirement 'sizeof(char) == sizeof(short)': type size mismatch}} \
                               // expected-note{{evaluates to '1 == 2'}} \
                               // ext-warning 3 {{'_Static_assert' is a C11 extension}}
typedef UNION(float, 0.5f) U4; // expected-error {{expected a type}} \
                               // ext-warning 3 {{'_Static_assert' is a C11 extension}}

// MSVC accepts static_assert in all language modes without including <assert.h>
// and so do we in ms-compatibility mode. Unfortunately, there is no good way
// to diagnose that with a pedantic warning. We'd have to track inclusion of
// <assert.h> which is difficult when modules and PCH are involved. Adding
// implicit definition of the macro causes unexpected results in c99 mode.
#ifdef MS

#if __STDC_VERSION__ < 201112L
#if defined(static_assert)
static_assert(0, "0 is nonzero"); // ok because we should not define static_assert
                                  // macro in c99.
#endif

static_assert(0, "0 is nonzero"); // ms-error {{static assertion failed: 0 is nonzero}}
#endif

#define assert(expr)
static_assert(1, "1 is nonzero"); // ok

#undef static_assert
static_assert(1, "1 is nonzero"); // yes, still ok.
#endif

_Static_assert(1 , "") // expected-error {{expected ';' after '_Static_assert'}} \
                      // ext-warning {{'_Static_assert' is a C11 extension}}

static int static_var;
_Static_assert(&static_var != 0, "");  // ext-warning {{'_Static_assert' is a C11 extension}} \
                                       // expected-warning {{comparison of address of 'static_var' not equal to a null pointer is always true}}
_Static_assert("" != 0, "");           // ext-warning {{'_Static_assert' is a C11 extension}}
_Static_assert(("" != 0), "");         // ext-warning {{'_Static_assert' is a C11 extension}}
_Static_assert(*"1", "");              // ext-warning {{'_Static_assert' is a C11 extension}}
_Static_assert("1"[0], "");            // ext-warning {{'_Static_assert' is a C11 extension}}
_Static_assert(1.0 != 0, "");          // ext-warning {{'_Static_assert' is a C11 extension}}
_Static_assert(__builtin_strlen("1"), "");  // ext-warning {{'_Static_assert' is a C11 extension}}
#ifndef __cplusplus
// expected-warning@-9 {{expression is not an integer constant expression; folding it to a constant is a GNU extension}}
// expected-warning@-8 {{expression is not an integer constant expression; folding it to a constant is a GNU extension}}
// expected-warning@-8 {{expression is not an integer constant expression; folding it to a constant is a GNU extension}}
// expected-warning@-8 {{expression is not an integer constant expression; folding it to a constant is a GNU extension}}
// expected-warning@-8 {{expression is not an integer constant expression; folding it to a constant is a GNU extension}}
// expected-warning@-8 {{expression is not an integer constant expression; folding it to a constant is a GNU extension}}
// __builtin_strlen(literal) is considered an integer constant expression
// and doesn't cause a pedantic warning
#endif


_Static_assert(0, L"\xFFFFFFFF"); // expected-warning {{encoding prefix 'L' on an unevaluated string literal has no effect}} \
                                  // expected-error {{invalid escape sequence '\xFFFFFFFF' in an unevaluated string literal}} \
                                  // expected-error {{hex escape sequence out of range}} \
                                  // ext-warning {{'_Static_assert' is a C11 extension}}
_Static_assert(0, L"\u1234"); // expected-warning {{encoding prefix 'L' on an unevaluated string literal has no effect}} \
                              // expected-error {{static assertion failed: ሴ}} \
                              // ext-warning {{'_Static_assert' is a C11 extension}}

_Static_assert(0, L"\x1ff"      // expected-warning {{encoding prefix 'L' on an unevaluated string literal has no effect}} \
                                // expected-error {{hex escape sequence out of range}} \
                                // expected-error {{invalid escape sequence '\x1ff' in an unevaluated string literal}} \
                                // ext-warning {{'_Static_assert' is a C11 extension}}
                   "0\x123"     // expected-error {{invalid escape sequence '\x123' in an unevaluated string literal}}
                   "fx\xfffff"  // expected-error {{invalid escape sequence '\xfffff' in an unevaluated string literal}}
                   "goop");
