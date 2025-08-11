FROM rust:1.79.0-buster AS builder

LABEL version="1.2.0"
LABEL name="Cosmian CLI and PKCS11 container"

# Add build argument for FIPS mode
ARG FIPS=false

WORKDIR /root

COPY . /root/cli

WORKDIR /root/cli

# Conditional cargo build based on FIPS argument
RUN if [ "$FIPS" = "true" ]; then \
  cargo build -p cosmian_cli -p cosmian_pkcs11 --release --no-default-features --features="fips"; \
  else \
  cargo build -p cosmian_cli -p cosmian_pkcs11 --release --no-default-features; \
  fi

#
# KMS server
#
FROM debian:buster-slim AS kms-server

COPY --from=builder /root/cli/target/release/cosmian                  /usr/bin/
COPY --from=builder /root/cli/target/release/libcosmian_pkcs11.so     /usr/lib/
