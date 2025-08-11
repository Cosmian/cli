#!/bin/bash

# From here, CLI/PKCS11 docker image has been build

set -ex

# Run Oracle database and KMS
cd crate/pkcs11/oracle
docker-compose down --remove-orphans
rm -rf keystore oradata
docker-compose up -d
cd ../../..
sleep 180

# Copy the Cosmian PKCS#11 library to Oracle image
bash ./github/scripts/oracle/set_hsm.sh
