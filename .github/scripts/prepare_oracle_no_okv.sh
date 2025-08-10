#!/bin/bash

set -ex

cargo build -p cosmian_pkcs11
bash .github/scripts/build_libpkcs11.sh

#
# Copy the Cosmian PKCS#11 library from the libpkcs11 Docker container
# Copy the configuration file of the Cosmian PKCS#11 library
#
cat <<'EOF' > setup_cosmian_pkcs11.sh
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

EOF
chmod +x setup_cosmian_pkcs11.sh

#
# Copy files and run setup script
#
docker cp libcosmian_pkcs11.so              oracle:/home/oracle/
docker cp crate/pkcs11/oracle/cosmian.toml  oracle:/home/oracle/
docker cp setup_cosmian_pkcs11.sh           oracle:/home/oracle/
docker exec -u root -it oracle bash -c "/home/oracle/setup_cosmian_pkcs11.sh"

#
# Setup Oracle TDE for HSM
#
cat <<EOF > config.sql
ALTER SYSTEM SET WALLET_ROOT='/opt/oracle/extapi/64/hsm/Cosmian/libcosmian_pkcs11.so' SCOPE = SPFILE;
ALTER SYSTEM SET TDE_CONFIGURATION="KEYSTORE_CONFIGURATION=HSM" scope=both;
SHOW PARAMETER WALLET_ROOT;
SHUTDOWN IMMEDIATE;
STARTUP;
exit
EOF

docker cp config.sql oracle:/tmp/config.sql
docker exec -u oracle -it oracle bash -c "sqlplus / as sysdba @/tmp/config.sql"

rm config.sql setup_cosmian_pkcs11.sh

# docker exec -it oracle sqlplus sys/1234@FREE as sysdba @/tmp/config.sql

# docker exec -it oracle sqlplus sys/1234@FREE as sysdba

# ALTER SYSTEM SET WALLET_ROOT='/opt/oracle/extapi/64/hsm/Cosmian/libcosmian_pkcs11.so' SCOPE = SPFILE;
# ALTER SYSTEM SET TDE_CONFIGURATION="KEYSTORE_CONFIGURATION=HSM" scope=both;
# SHOW PARAMETER WALLET_ROOT
# SHUTDOWN IMMEDIATE;
# STARTUP;

# ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "admin";
# COLUMN WRL_PARAMETER FORMAT A50;
# SET LINES 200;
# SELECT WRL_TYPE, WRL_PARAMETER, WALLET_TYPE, STATUS FROM V$ENCRYPTION_WALLET;

# ADMINISTER KEY MANAGEMENT SET KEYSTORE CLOSE IDENTIFIED BY "admin";
# ADMINISTER KEY MANAGEMENT SET KEYSTORE CLOSE CONTAINER = ALL;
