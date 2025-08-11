#!/bin/bash

set -ex

#
# Copy the Cosmian PKCS#11 library from the libpkcs11 Docker container
# Manual docker build:
# docker buildx build --progress=plain --platform linux/arm64 -t dll_p11 .
#

rm -f libcosmian_pkcs11.so

if [ -z "${DOCKER_IMAGE_NAME}" ]; then
  DOCKER_IMAGE_NAME="dll_p11"
  # docker buildx build --progress=plain --platform linux/arm64 -t ${DOCKER_IMAGE_NAME} .
fi

# Run container to make files copy from it
docker run --rm --name dll_p11 -d "${DOCKER_IMAGE_NAME}" tail -f /dev/null
sleep 5

if [ -z "${DOCKER_IMAGE_NAME}" ]; then
  docker cp dll_p11:/data/target/release/libcosmian_pkcs11.so .
else
  docker cp dll_p11:/usr/lib/libcosmian_pkcs11.so .
fi

#
# Copy the configuration file of the Cosmian PKCS#11 library
#
cat <<'EOF' >setup_cosmian_pkcs11.sh
set -ex

mkdir -p /opt/oracle/extapi/64/hsm/Cosmian/
mv /home/oracle/libcosmian_pkcs11.so /opt/oracle/extapi/64/hsm/Cosmian/
chown oracle:oinstall /opt/oracle/extapi/64/hsm/Cosmian/libcosmian_pkcs11.so

mkdir -p /home/oracle/.cosmian/
mv /home/oracle/cosmian.toml /home/oracle/.cosmian/
chown oracle:oinstall /home/oracle/.cosmian/cosmian.toml

mkdir -p /etc/ORACLE/KEYSTORES/FREE
chown -R oracle:oinstall /etc/ORACLE/KEYSTORES/FREE

chown -R oracle:oinstall /var/log
rm -f /var/log/cosmian-pkcs11.log

mkdir -p /etc/ORACLE/KEYSTORES/FREE
chown -R oracle:oinstall /etc/ORACLE/KEYSTORES/FREE

EOF
chmod +x setup_cosmian_pkcs11.sh

#
# Copy files and run setup script
#
docker cp libcosmian_pkcs11.so oracle:/home/oracle/
docker cp crate/pkcs11/oracle/cosmian.toml oracle:/home/oracle/
docker cp setup_cosmian_pkcs11.sh oracle:/home/oracle/
docker exec -u root oracle bash -c "/home/oracle/setup_cosmian_pkcs11.sh"
rm setup_cosmian_pkcs11.sh libcosmian_pkcs11.so

#
# Setup Oracle TDE for HSM
#
bash .github/scripts/oracle/run_sql_commands.sh
