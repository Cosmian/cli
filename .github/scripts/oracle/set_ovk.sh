#!/bin/bash

set -ex

bash .github/scripts/build_libpkcs11.sh

# SSH config:
# Host okv
#     HostName 192.168.1.210
#     User cosmian
#     IdentityFile ~/.ssh/id_rsa

# Copy the library to the OKV server
scp libcosmian_pkcs11.so okv:
ssh okv "sudo cp ~/libcosmian_pkcs11.so /usr/local/okv/hsm/generic/"
ssh okv "sudo chown oracle:oinstall /usr/local/okv/hsm/generic/libcosmian_pkcs11.so"
ssh okv "sudo rm -f /var/okv/log/hsm/*"

#
# Copy CLI config
#
scp crate/pkcs11/oracle/cosmian.toml okv:
ssh okv "sudo mv ~/cosmian.toml /usr/local/okv/hsm/generic"
ssh okv "sudo chown oracle:oinstall /usr/local/okv/hsm/generic/cosmian.toml"

#
# Copy OKV generic HSM variables env. file
#
scp crate/pkcs11/oracle/okv_hsm_env okv:
ssh okv "sudo mv ~/okv_hsm_env /usr/local/okv/hsm/generic/okv_hsm_env"
ssh okv "sudo chown oracle:oinstall /usr/local/okv/hsm/generic/okv_hsm_env"

#
# Copy OKV generic HSM config file
#
scp crate/pkcs11/oracle/okv_hsm_conf okv:
ssh okv "sudo mv ~/okv_hsm_conf /usr/local/okv/hsm/generic/okv_hsm_conf"
ssh okv "sudo chown oracle:oinstall /usr/local/okv/hsm/generic/okv_hsm_conf"
