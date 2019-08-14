#!/bin/sh
###############################################################################
# This will combine keys in a cwe for deployment
#
# Copyright (c) 2019 Sierra Wireless Inc.
#
# Usage example: swi-key-cwe verity.x509.pem
# CERTPEM="build_src/tmp/work-shared/android-signing/security/verity.x509.pem"
#
###############################################################################

if [ "$#" -gt 0 ]; then
  CERTPEM=$1
fi

echo "input cert: ${CERTPEM}"

# if hdrcnv is not present in your system, make sure the full path is given
# HDRCNV="build_src/tmp/sysroots/x86_64-linux/usr/bin/hdrcnv"
HDRCNV="hdrcnv"

# Convert the cert to der format
openssl x509 -outform der -in ${CERTPEM} -out verity.x509.der

# 8 zeros of control info
dd if=/dev/zero bs=8 count=1 >keys.bin
openssl dgst -binary -sha256 verity.x509.der >>keys.bin

$HDRCNV keys.bin -OH keys.hdr -IT KEYS -PT 9X28 -V "KEYS V0" -B 00000001
dd if=keys.hdr >swi-keys.cwe
dd if=keys.bin >>swi-keys.cwe
rm -f keys.hdr keys.bin verity*
