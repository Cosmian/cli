#!/bin/bash

set -ex

# docker stop lib_pkcs11 || true
# docker rm lib_pkcs11 || true
# docker rmi libpkcs11_buster || true
# docker buildx build --progress=plain --platform linux/arm64 -t libpkcs11_buster .

# docker run --rm --name lib_pkcs11 -d libpkcs11_buster tail -f /dev/null
# sleep 5

# docker cp lib_pkcs11:/usr/bin/libcosmian_pkcs11.so .
docker cp dll_p11:/data/target/release/libcosmian_pkcs11.so .
