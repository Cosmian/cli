#!/bin/bash

set -exo pipefail

# export FEATURES="non-fips"

if [ -z "$TARGET" ]; then
  echo "Error: TARGET is not set. Examples of TARGET are x86_64-unknown-linux-gnu, x86_64-apple-darwin, aarch64-apple-darwin."
  exit 1
fi

if [ "$DEBUG_OR_RELEASE" = "release" ]; then
  RELEASE="--release"
fi

if [ -n "$FEATURES" ]; then
  FEATURES="--features $FEATURES"
fi

if [ -z "$FEATURES" ]; then
  echo "Info: FEATURES is not set."
  unset FEATURES
fi

if [ -z "$OPENSSL_DIR" ]; then
  echo "Error: OPENSSL_DIR is not set. Example OPENSSL_DIR=/usr/local/openssl"
  exit 1
fi

rustup target add "$TARGET"

# shellcheck disable=SC2086
cargo build -p cosmian_cli -p cosmian_pkcs11 --target $TARGET $RELEASE $FEATURES

COSMIAN_CLI_EXE="target/$TARGET/$DEBUG_OR_RELEASE/cosmian"

# Test binary functionality
."/$COSMIAN_CLI_EXE" --help

# Check for dynamic OpenSSL linkage
if [ "$(uname)" = "Linux" ]; then
  LDD_OUTPUT=$(ldd "$COSMIAN_CLI_EXE")
  echo "$LDD_OUTPUT"
  if echo "$LDD_OUTPUT" | grep -qi ssl; then
    echo "Error: Dynamic OpenSSL linkage detected on Linux (ldd | grep ssl)."
    exit 1
  fi
else
  OTOOL_OUTPUT=$(otool -L "$COSMIAN_CLI_EXE")
  echo "$OTOOL_OUTPUT"
  if echo "$OTOOL_OUTPUT" | grep -qi ssl; then
    echo "Error: Dynamic OpenSSL linkage detected on macOS (otool -L | grep openssl)."
    exit 1
  fi
fi
