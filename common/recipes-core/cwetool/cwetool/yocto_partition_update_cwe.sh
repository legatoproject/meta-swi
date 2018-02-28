#!/bin/sh

TARGET="$1"
[ -z "$TARGET" ] && echo "Missing target" && exit 1

rm -f full_update_yocto_$TARGET.* boot_update_yocto_$TARGET.*
python `dirname $0`/partition_update.py custom_partition.xml partition.mbn
[ $? -ne 0 ] && exit 1

FW=`cat firmware_version.txt`
TAG1=$FW"_CUSTOM_PARTITION_`date | sed 's/ /_/g'`"
TAG2="INTERNAL_?_"$FW"_?_?_?_?"
hdrcnv partition.mbn -OH partition.hdr -IT QPAR -PT 9x15 -V "AR_4G4K" -B 00000001
dd if=partition.hdr >partition.cwe
dd if=partition.mbn >>partition.cwe
dd if=all.mbn >>partition.cwe
rm -f partition.mbn all.mbn
hdrcnv partition.cwe -OH boot_update_yocto_$TARGET.hdr -IT BOOT -PT A911 -V "$TAG1" -B 00000001
[ $? -ne 0 ] && exit 1
dd if=boot_update_yocto_$TARGET.hdr >boot_update_yocto_$TARGET.cwe
[ $? -ne 0 ] && exit 1
dd if=partition.cwe >>boot_update_yocto_$TARGET.cwe
[ $? -ne 0 ] && exit 1
rm -f partition.cwe partition.hdr rpm.hdr sbl1.hdr boot_update_yocto_$TARGET.hdr

dd if=boot_update_yocto_$TARGET.cwe >full_update_yocto_$TARGET.bin
[ $? -ne 0 ] && exit 1
dd if=modemz.cwe >>full_update_yocto_$TARGET.bin
[ $? -ne 0 ] && exit 1
dd if=boot-yocto-legato_$TARGET.cwe >>full_update_yocto_$TARGET.bin
[ $? -ne 0 ] && exit 1

hdrcnv full_update_yocto_$TARGET.bin -OH full_update_yocto_$TARGET.hdr -IT SPKG -PT A911 -V "$TAG2" -B 00000001
[ $? -ne 0 ] && exit 1
dd if=full_update_yocto_$TARGET.hdr >full_update_yocto_$TARGET.cwe
[ $? -ne 0 ] && exit 1
dd if=full_update_yocto_$TARGET.bin >>full_update_yocto_$TARGET.cwe
[ $? -ne 0 ] && exit 1
rm -f full_update_yocto_$TARGET.hdr full_update_yocto_$TARGET.bin
exit 0
