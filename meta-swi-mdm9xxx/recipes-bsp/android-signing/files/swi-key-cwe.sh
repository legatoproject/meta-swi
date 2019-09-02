#!/bin/sh -e
#
# Copyright (c) 2019 Sierra Wireless Inc.
#
# This script creates keystore cwe, to be downloaded
# to enable specific security features
# - Linux secure boot (signed images = lk, kernel etc)
# - dm-verity for RootFS (signed images = yocto, legato etc)
#
# Usage examples to create keysorte cwe file:
# - for Linux secure boot:
#   ./swi-key-cwe.sh <certificate>
#   output file = swi-keys-<cert's sha>.cwe, symlink = swi-keys.cwe
# - for dm-verity for RootFS:
#   ./swi-key-cwe.sh <certificate> 9X28 RFS0
#   output file = RFS0-keys-<cert's sha>.cwe, symlink = RFS0-keys.cwe
# - for dm-verity for Legato:
#   ./swi-key-cwe.sh <certificate> 9X28 LGT0
#   output file = LGT0-keys-<cert's sha>.cwe, symlink = LGT0-keys.cwe
#

# specify the path of hdrcnv according to your system
HDRCNV="build_src/tmp/sysroots-components/x86_64/cwetool-native/usr/bin/hdrcnv"
if [ -x common/sierra/hdrcnv ]; then
  HDRCNV="common/sierra/hdrcnv"
fi

CERTPEM="build_src/tmp/work-shared/android-signing/security/verity.x509.pem"
PRODUCT="9X28"
CWE_PREFIX="keys"
CWE_LABEL=""
KEY_ID=""

if [ -n "$1" ]; then
  CERTPEM=$1
fi
if [ -n "$2" ]; then
  PRODUCT=$2
fi
if [ -n "$3" ]; then
  KEY_ID=$3
fi
if [ -n "$4" ]; then
  CWE_LABEL=$4
fi


if [ ! -f $CERTPEM ]; then
  echo "example usage:"
  echo "  ./swi-key-cwe.sh <certificate>"
  echo "  ./swi-key-cwe.sh <certificate> 9X28 RFS0"
  echo "  ./swi-key-cwe.sh <certificate> 9X28 LGT0"
  exit
fi

# version 0 key with zero filled header
KEY_VER=0
if [ -n "$KEY_ID" ]; then
  # version 1 key with header filled
  KEY_VER=1
fi

if [ -z "$CWE_LABEL" ]; then
  CWE_LABEL="KEYS"
  # prepend prefix when CWE_LABEL is not given
  if [ $KEY_VER -eq 0 ]; then
    # version 0, name it as a swi key
    CWE_PREFIX="swi-$CWE_PREFIX"
  else
    # prepend with KEY_ID
    CWE_PREFIX="${KEY_ID// /-}-${CWE_PREFIX}"
  fi
else
  # prepend prefix with CWE_LABEL given
  CWE_PREFIX="${CWE_LABEL// /-}-${CWE_PREFIX}"
fi

# append key version
CWE_LABEL="$CWE_LABEL V${KEY_VER}"

cat <<EOM
Input values:
  Input cert = $CERTPEM
  CWE label  = $CWE_LABEL
  Key ID     = $KEY_ID
  Product    = $PRODUCT
EOM

if [[ "${CERTPEM}" = *".der" ]]; then
  # already in der format
  cp "${CERTPEM}" verity.x509.der
else
  #convert the cert to der format
  openssl x509 -outform der -in "${CERTPEM}" -out verity.x509.der
fi

update_keystore_header_v1 () {
  key_type=$1
  filesize=$2
  key_id=$3

  # Version=1
  # bytes [0:2] | control-info=1 (1 byte) followed by key_type (1 byte)
  printf "01 %02x" "$key_type" | xxd -r -p - keys.bin
  # bytes [3:4] | filesize (uint16) in little endian, excluded 8 bytes header
  printf "%.4x" "$(($filesize-8))" | xxd -r -p | dd conv=swab,notrunc seek=2 oflag=seek_bytes status=none of=keys.bin
  # bytes [5:8] | 4 bytes ascii of key_id
  printf "%-.4s" "$key_id" | dd conv=notrunc seek=4 oflag=seek_bytes status=none of=keys.bin
}

# write zero 8 bytes header
dd if=/dev/zero bs=8 count=1 status=none >keys.bin
# write key payload
openssl dgst -binary -sha256 verity.x509.der >>keys.bin

if [ $KEY_VER -ne 0 ]; then
  # Update key header for version 1
  update_keystore_header_v1 0 `stat -c "%s" keys.bin` "$KEY_ID"
fi

sharoot=`openssl dgst -sha256 "$CERTPEM" | awk '{print $2}'`

cwe_file="${CWE_PREFIX}-${sharoot:0:7}.cwe"
echo "CWE file   = $cwe_file"

$HDRCNV keys.bin -OH keys.hdr -IT KEYS -PT "$PRODUCT" -V "$CWE_LABEL" -B 00000001
dd if=keys.hdr status=none >$cwe_file
dd if=keys.bin status=none >>$cwe_file
# create a symlink without suffix sharoot as the fixed name output
ln -sf $cwe_file "${CWE_PREFIX}.cwe"

rm -f keys.hdr keys.bin verity*
