#!/bin/sh
###############################################################################
# This will combine keys in a cwe for deployment on an oem rfs
#
# Copyright (c) 2019 Sierra Wireless Inc.
#
# Usage example: swi-key-rfs0-cwe.sh verity.x509.pem testkey.x509.pem
# CERTPEM="build_src/tmp/work-shared/android-signing/security/verity.x509.pem"
# DM_CERTPEM="build_src/tmp/work-shared/android-signing/security/testkey.x509.pem"
#
###############################################################################

if [ "$#" -gt 0 ]; then
  CERTPEM=$1
  DM_CERTPEM=$2
fi

echo "input OEM cert: ${CERTPEM}"
echo "input RootFS cert: ${DM_CERTPEM}"

# if hdrcnv is not present in your system, make sure the full path is given
# HDRCNV="build_src/tmp/sysroots/x86_64-linux/usr/bin/hdrcnv"
HDRCNV="hdrcnv"

wrap_v1_key_hdr () {
  file=$1
  key_type=$2
  key_id=$3

  filesize=`stat -c "%s" $file`
  echo "filesize: " $filesize

  # set second byte of control-info as 1
  echo "00: 01 $key_type" | xxd -r > ctl-info.bin

  # file size byte swap
  printf "0: %.4x" $filesize | sed -E 's/0: (..)(..)/0: \2\1/' | xxd -r -g0 >> ctl-info.bin

  # set key id
  printf $key_id >> ctl-info.bin
  cat ctl-info.bin $file >> keys.bin
}

# OEM cert digest
## convert the cert to der format
openssl x509 -outform der -in ${CERTPEM} -out verity.x509.der
## 8 zeros of control info
dd if=/dev/zero bs=8 count=1 >keys.bin
openssl dgst -binary -sha256 verity.x509.der >>keys.bin


# dm-verity cert digest
## convert the cert to der format
openssl x509 -outform der -in ${DM_CERTPEM} -out testkey.x509.der
openssl dgst -binary -sha256 testkey.x509.der >dm-rot.bin
wrap_v1_key_hdr "dm-rot.bin" "00" "RFS0" # appended to keys.bin


$HDRCNV keys.bin -OH keys.hdr -IT KEYS -PT 9X28 -V "KEYS V1" -B 00000001
dd if=keys.hdr >oem-rfs-keys.cwe
dd if=keys.bin >>oem-rfs-keys.cwe
rm -f keys.hdr keys.bin verity* testkey*
