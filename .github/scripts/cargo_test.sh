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

export RUST_LOG="cosmian_cli=error,cosmian_findex_client=debug,cosmian_kms_client=debug"

# shellcheck disable=SC2086
cargo test --workspace --bins --target $TARGET $RELEASE $FEATURES

# shellcheck disable=SC2086
# cargo bench --target $TARGET $FEATURES --no-run

export RUST_LOG="fatal,cosmian_cli=error,cosmian_findex_client=debug,cosmian_kms_client=debug"

# shellcheck disable=SC2086
cargo test --target $TARGET $RELEASE \
  --features non-fips \
  -p cosmian_cli \
  -p cosmian_pkcs11 \
  -- --nocapture 

if [ -f /etc/lsb-release ]; then
  export HSM_USER_PASSWORD="12345678"

  # Install Utimaco simulator and run tests
  bash .github/reusable_scripts/test_utimaco.sh

  # Install SoftHSM2 and run tests
  sudo apt-get install -y libsofthsm2
  sudo softhsm2-util --init-token --slot 0 --label "my_token_1" --so-pin "$HSM_USER_PASSWORD" --pin "$HSM_USER_PASSWORD"

  UTIMACO_HSM_SLOT_ID=0
  SOFTHSM2_HSM_SLOT_ID=$(sudo softhsm2-util --show-slots | grep -o "Slot [0-9]*" | head -n1 | awk '{print $2}')

  # HSM tests with uniformized loop
  declare -a HSM_MODELS=('utimaco' 'softhsm2')
  for HSM_MODEL in "${HSM_MODELS[@]}"; do
    if [ "$HSM_MODEL" = "utimaco" ]; then
      HSM_SLOT_ID="$UTIMACO_HSM_SLOT_ID"
      HSM_PACKAGE="utimaco_pkcs11_loader"
      HSM_FEATURE="utimaco"
    else
      HSM_SLOT_ID="$SOFTHSM2_HSM_SLOT_ID"
      HSM_PACKAGE="softhsm2_pkcs11_loader"
      HSM_FEATURE="softhsm2"
    fi

    # Test HSM package directly
    # shellcheck disable=SC2086
    sudo -E env "PATH=$PATH" HSM_MODEL="$HSM_MODEL" HSM_USER_PASSWORD="$HSM_USER_PASSWORD" HSM_SLOT_ID="$HSM_SLOT_ID" \
      cargo test -p "$HSM_PACKAGE" --target "$TARGET" $RELEASE --features "$HSM_FEATURE" -- tests::test_hsm_${HSM_MODEL}_all --ignored

    # Test HSM integration with KMS server
    # shellcheck disable=SC2086
    sudo -E env "PATH=$PATH" HSM_MODEL="$HSM_MODEL" HSM_USER_PASSWORD="$HSM_USER_PASSWORD" HSM_SLOT_ID="$HSM_SLOT_ID" \
      cargo test --target "$TARGET" $FEATURES $RELEASE -- tests::hsm::test_hsm_all --ignored
  done
fi
