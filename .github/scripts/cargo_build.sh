#!/bin/bash

set -ex

# --- Declare the following variables for tests
# export TARGET=x86_64-unknown-linux-gnu
# export DEBUG_OR_RELEASE=debug
# export OPENSSL_DIR=/usr/local/openssl
# export SKIP_SERVICES_TESTS="--skip test_encrypt --skip test_create"

ROOT_FOLDER=$(pwd)

if [ "$DEBUG_OR_RELEASE" = "release" ]; then
  # First build the Debian and RPM packages. It must come at first since
  # after this step `ckms` and `cosmian_kms_server` are built with custom features flags (fips for example).
  rm -rf target/"$TARGET"/debian
  rm -rf target/"$TARGET"/generate-rpm
  if [ -f /etc/redhat-release ]; then
    cd crate/cli && cargo build --target "$TARGET" --release && cd -
    cd crate/server && cargo build --target "$TARGET" --release && cd -
    cargo install --version 0.14.1 cargo-generate-rpm --force
    cd "$ROOT_FOLDER"
    cargo generate-rpm --target "$TARGET" -p crate/cli
    cargo generate-rpm --target "$TARGET" -p crate/server --metadata-overwrite=pkg/rpm/scriptlets.toml
  elif [ -f /etc/lsb-release ]; then
    cargo install --version 2.4.0 cargo-deb --force
    cargo deb --target "$TARGET" -p cosmian_kms_cli --variant fips
    cargo deb --target "$TARGET" -p cosmian_kms_cli
    cargo deb --target "$TARGET" -p cosmian_kms_server --variant fips
    cargo deb --target "$TARGET" -p cosmian_kms_server
  fi
fi

if [ -z "$TARGET" ]; then
  echo "Error: TARGET is not set."
  exit 1
fi

if [ "$DEBUG_OR_RELEASE" = "release" ]; then
  RELEASE="--release"
fi

if [ -z "$SKIP_SERVICES_TESTS" ]; then
  echo "Info: SKIP_SERVICES_TESTS is not set."
  unset SKIP_SERVICES_TESTS
fi

rustup target add "$TARGET"

cd "$ROOT_FOLDER"

if [ -z "$OPENSSL_DIR" ]; then
  echo "Error: OPENSSL_DIR is not set."
  exit 1
fi

crates=("crate/gui" "crate/cli")
for crate in "${crates[@]}"; do
  echo "Building $crate"
  cd "$crate"
  # shellcheck disable=SC2086
  cargo build --target $TARGET $RELEASE $FEATURES
  cd "$ROOT_FOLDER"
done

# Debug
# find .

TARGET_FOLDER=./target/"$TARGET/$DEBUG_OR_RELEASE"
"${TARGET_FOLDER}"/cosmian -h
"${TARGET_FOLDER}"/cosmian_gui -h

if [ "$(uname)" = "Linux" ]; then
  ldd "${TARGET_FOLDER}"/cosmian | grep ssl && exit 1
  ldd "${TARGET_FOLDER}"/cosmian_gui | grep ssl && exit 1
else
  otool -L "${TARGET_FOLDER}"/cosmian | grep openssl && exit 1
  otool -L "${TARGET_FOLDER}"/cosmian_gui | grep openssl && exit 1
fi

find . -type d -name cosmian-kms -exec rm -rf \{\} \; -print || true
rm -f /tmp/*.json

export RUST_LOG="cosmian_kms_cli=debug,cosmian_gui=debug"

# shellcheck disable=SC2086
cargo build --target $TARGET $RELEASE $FEATURES

# shellcheck disable=SC2086
cargo test --target $TARGET $RELEASE $FEATURES --workspace -- --nocapture $SKIP_SERVICES_TESTS