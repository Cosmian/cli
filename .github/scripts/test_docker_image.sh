#!/bin/bash

# From here, CLI/PKCS11 docker image has been build

set -ex

# Run Oracle database and KMS
docker compose -f crate/pkcs11/oracle/docker-compose.yml down --remove-orphans
docker compose -f crate/pkcs11/oracle/docker-compose.yml up -d --wait

# Copy the Cosmian PKCS#11 library to Oracle image
bash .github/scripts/oracle/set_hsm.sh
