#!/bin/bash

set -ex

###
### Those commands can be used to rebuild the Cosmian PKCS#11 library with an old GLIBC (compatible with Oracle DB image)
###
# docker stop lib_pkcs11 || true
# docker rm lib_pkcs11 || true
# docker rmi libpkcs11_buster || true
# docker buildx build --progress=plain --platform linux/arm64 -t libpkcs11_buster .

# docker run --rm --name lib_pkcs11 -d libpkcs11_buster tail -f /dev/null
# sleep 5

# docker cp lib_pkcs11:/usr/bin/libcosmian_pkcs11.so .

###
### Otherwise use the CI pre-built library
###
docker cp dll_p11:/data/target/release/libcosmian_pkcs11.so .
