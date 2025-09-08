#!/bin/bash

set -ex

rm -f libcosmian_pkcs11.so
if [ -z "${DOCKER_IMAGE_NAME}" ]; then
  docker cp dll_p11:/data/target/release/libcosmian_pkcs11.so .
else
  # Run container to make files copy from it
  # export DOCKER_IMAGE_NAME=ghcr.io/cosmian/cli:1.3.0
  docker buildx build --progress=plain --platform linux/amd64 -t dll_p11 .
  export DOCKER_IMAGE_NAME=dll_p11
  docker stop dll_p11 || true
  docker run --platform linux/amd64 --rm --name dll_p11 -d "${DOCKER_IMAGE_NAME}" tail -f /dev/null
  sleep 5
  docker cp dll_p11:/usr/lib/libcosmian_pkcs11.so .
fi

# SSH config:
# Host okv
#     HostName 192.168.1.210
#     User cosmian
#     IdentityFile ~/.ssh/id_rsa

# Copy the library to the OKV server
scp -O libcosmian_pkcs11.so okv:
ssh okv "sudo cp ~/libcosmian_pkcs11.so /usr/local/okv/hsm/generic/"
ssh okv "sudo chown oracle:oinstall /usr/local/okv/hsm/generic/libcosmian_pkcs11.so"
ssh okv "sudo rm -f /var/okv/log/hsm/*"

#
# Copy CLI config
#
scp -O crate/pkcs11/oracle/cosmian_okv.toml okv:cosmian.toml
ssh okv "sudo mv ~/cosmian.toml /usr/local/okv/hsm/generic"
ssh okv "sudo chown oracle:oinstall /usr/local/okv/hsm/generic/cosmian.toml"

#
# Copy OKV generic HSM variables env. file
#
scp -O crate/pkcs11/oracle/okv_hsm_env okv:
ssh okv "sudo mv ~/okv_hsm_env /usr/local/okv/hsm/generic/okv_hsm_env"
ssh okv "sudo chown oracle:oinstall /usr/local/okv/hsm/generic/okv_hsm_env"

#
# Copy OKV generic HSM config file
#
scp -O crate/pkcs11/oracle/okv_hsm_conf okv:
ssh okv "sudo mv ~/okv_hsm_conf /usr/local/okv/hsm/generic/okv_hsm.conf"
ssh okv "sudo chown oracle:oinstall /usr/local/okv/hsm/generic/okv_hsm.conf"
