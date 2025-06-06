//===-- Implementation of strcoll_l ---------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "src/string/strcoll_l.h"

#include "src/__support/common.h"
#include "src/__support/macros/config.h"
#include "src/__support/macros/null_check.h"

namespace LIBC_NAMESPACE_DECL {

// TODO: Add support for locales.
LLVM_LIBC_FUNCTION(int, strcoll_l,
                   (const char *left, const char *right, locale_t)) {
  LIBC_CRASH_ON_NULLPTR(left);
  LIBC_CRASH_ON_NULLPTR(right);
  for (; *left && *left == *right; ++left, ++right)
    ;
  return static_cast<int>(*left) - static_cast<int>(*right);
}

} // namespace LIBC_NAMESPACE_DECL
