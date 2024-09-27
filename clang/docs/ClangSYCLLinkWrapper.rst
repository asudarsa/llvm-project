====================
Clang SYCL link Wrapper
====================

.. contents::
   :local:

.. _clang-sycl-link-wrapper:

Introduction
============

This tool works as a wrapper around the SYCL device code linking process.
Purpose of this wrapper is to provide an interface to link SYCL device bitcode
in LLVM IR format, run some SYCL-specific finalization steps and then use the
SPIR-V LLVM Translator tool to produce the final output.

Device code linking for SYCL offloading kind has a number of known quirks that
makes it difficult to use in a unified offloading setting. Two of the primary
issues are:
1. Several finalization steps are required to be run on the fully-linked LLVM
IR bitcode to gaurantee conformance to SYCL standards. This step is unique to
SYCL offloading compilation flow.
2. SPIR-V LLVM Translator tool is an extenal tool and hence SPIR-V IR code
generation cannot be done as part of LTO. This limitation will be lifted once
SPIR-V backend is available as a viable LLVM backend.

This tool works around these issues.

Usage
=====

This tool can be used with the following options. Several of these options will
be passed down to downstrea tools like 'llvm-link', 'llvm-spirv', etc.

.. code-block:: console

  OVERVIEW: A utility that wraps around the SYCl device code linking process.
  This enables linking and code generation for SPIR-V JIT targets.

  USAGE: clang-sycl-link-wrapper [options]

  OPTIONS:
    --arch <value>       Specify the name of the target architecture.
    --dry-run            Print generated commands without running.
    -g                   Specify that this was a debug compile.
    -help-hidden         Display all available options
    -help                Display available options (--help-hidden for more)
    --library-path=<dir> Set the library path for SYCL device libraries
    -o <path>            Path to file to write output
    --save-temps         Save intermediate results
    --triple <value>     Specify the target triple.
    --version            Display the version number and exit
    -v                   Print verbose information

Example
=======

This tool is intended to be invoked when targeting the SPIR-V toolchain.
When --sycl-link option is passed, clang driver will invoke the linking job of
the SPIR-V toolchain, which in turn will invoke this tool.
This tool can be used to create one or more fully linked SYCL objects that are
ready to be wrapped and linked with host code to generate the final executable.

.. code-block:: console

  clang --target=spirv64 --sycl-link input.bc
