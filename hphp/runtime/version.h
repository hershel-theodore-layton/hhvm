#pragma once

// This file needs to be valid C, not just C++

/* cmake -DHHVM_VERSION_OVERRIDE=3.12.0-dev .
 * Allows packaging scripts to update the reported
 * version without amending a commit to change this file
 *
 * See: CMake/HHVMVersion.cmake
 */
#ifndef HHVM_VERSION_OVERRIDE
# define HHVM_VERSION_MAJOR 26
# define HHVM_VERSION_MINOR 9
# define HHVM_VERSION_PATCH 29
# define HHVM_VERSION_SUFFIX ""
#endif

/* HHVM_VERSION_ID minus the patch number
 * APIs should remain stable while this number is constant
 */
#define HHVM_VERSION_BRANCH ((HHVM_VERSION_MAJOR << 16) | \
                             (HHVM_VERSION_MINOR <<  8))

/* Specific HHVM release */
#define HHVM_VERSION_ID (HHVM_VERSION_BRANCH | HHVM_VERSION_PATCH)

#define HHVM_VERSION_STRINGIFY_HELPER(x) #x
#define HHVM_VERSION_STRINGIFY(x) HHVM_VERSION_STRINGIFY_HELPER(x)

/* Zero-pad the month and day in calendar release versions. */
#if HHVM_VERSION_MINOR < 10
# define HHVM_VERSION_MINOR_STRING "0" HHVM_VERSION_STRINGIFY(HHVM_VERSION_MINOR)
#else
# define HHVM_VERSION_MINOR_STRING HHVM_VERSION_STRINGIFY(HHVM_VERSION_MINOR)
#endif
#if HHVM_VERSION_PATCH < 10
# define HHVM_VERSION_PATCH_STRING "0" HHVM_VERSION_STRINGIFY(HHVM_VERSION_PATCH)
#else
# define HHVM_VERSION_PATCH_STRING HHVM_VERSION_STRINGIFY(HHVM_VERSION_PATCH)
#endif

/* Human readable version string (e.g. "26.09.29") */
#define HHVM_VERSION_C_STRING_LITERALS \
  HHVM_VERSION_STRINGIFY(HHVM_VERSION_MAJOR) "." \
  HHVM_VERSION_MINOR_STRING "." \
  HHVM_VERSION_PATCH_STRING HHVM_VERSION_SUFFIX
#define HHVM_VERSION (HHVM_VERSION_C_STRING_LITERALS)
